const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'llama3';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

const MEDICAL_SYSTEM_PROMPT = `You are "Rakshak", a compassionate and knowledgeable virtual health assistant integrated into an Intelligent Healthcare System for Early Disease Prediction.

Your responsibilities:
1. Listen to user symptoms carefully and ask follow-up questions.
2. Provide general health guidance — NOT definitive medical diagnosis.
3. Classify every response with a risk tag:
   - [RISK:NORMAL] for general wellness/advice
   - [RISK:CAUTION] for symptoms that need monitoring
   - [RISK:URGENT] for potentially serious conditions needing immediate medical attention
4. Always recommend consulting a real doctor for concerning symptoms.
5. Be empathetic, clear, and use simple language.
6. When analyzing medical reports, explain values in layman's terms.
7. For emergencies, clearly state "Please contact emergency services immediately."

IMPORTANT: Always include exactly one risk tag in your response: [RISK:NORMAL], [RISK:CAUTION], or [RISK:URGENT].
Keep responses concise (under 300 words).`;

class AiService {
  constructor() {
    this.baseUrl = OLLAMA_URL;
    this.model = OLLAMA_MODEL;
    this.geminiKey = GEMINI_API_KEY;
  }

  async checkHealth() {
    if (this.geminiKey) return { status: 'ok', provider: 'Google Gemini', active: true };
    try {
      const res = await fetch(`${this.baseUrl}/api/tags`);
      if (!res.ok) throw new Error('Ollama not reachable');
      return { status: 'ok', provider: 'Ollama', activeModel: this.model };
    } catch (err) {
      return { status: 'error', provider: 'Ollama', message: `Ollama not running locally.` };
    }
  }

  _parseRisk(text) {
    if (text.includes('[RISK:URGENT]')) return 'urgent';
    if (text.includes('[RISK:CAUTION]')) return 'caution';
    return 'normal';
  }

  _cleanText(text) {
    return text
      .replace(/\[RISK:NORMAL\]/gi, '')
      .replace(/\[RISK:CAUTION\]/gi, '')
      .replace(/\[RISK:URGENT\]/gi, '')
      .trim();
  }

  async chat(messages, userMessage, base64Image = null) {
    if (this.geminiKey) {
      return this._chatGemini(messages, userMessage, base64Image);
    }
    return this._chatOllama(messages, userMessage, base64Image);
  }

  async _chatGemini(messages, userMessage, base64Image = null) {
    try {
      const contents = [];
      
      // Add history
      if (messages && messages.length > 0) {
        for (const msg of messages) {
          contents.push({
            role: msg.is_user ? 'user' : 'model',
            parts: [{ text: msg.text || msg.content }]
          });
        }
      }

      // Add current message
      const userPart = { text: MEDICAL_SYSTEM_PROMPT + "\n\nUser: " + userMessage };
      const parts = [userPart];

      if (base64Image) {
        const cleanBase64 = base64Image.includes(',') ? base64Image.split(',')[1] : base64Image;
        parts.push({
          inline_data: {
            mime_type: "image/jpeg",
            data: cleanBase64
          }
        });
      }

      contents.push({ role: 'user', parts });

      const url = `https://generativelanguage.googleapis.com/v1beta/models/${base64Image ? 'gemini-1.5-flash' : 'gemini-1.5-flash'}:generateContent?key=${this.geminiKey}`;
      
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents })
      });

      if (!res.ok) throw new Error(`Gemini Error: ${res.statusText}`);

      const data = await res.json();
      const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text || 'No response from AI.';
      
      return {
        text: this._cleanText(rawText),
        risk: this._parseRisk(rawText),
        provider: 'gemini'
      };
    } catch (err) {
      console.error('Gemini Error:', err);
      return { text: `⚠️ Gemini Error: ${err.message}`, risk: 'normal', error: true };
    }
  }

  async _chatOllama(messages, userMessage, base64Image = null) {
    const ollamaMessages = [{ role: 'system', content: MEDICAL_SYSTEM_PROMPT }];
    if (messages) {
      messages.forEach(msg => ollamaMessages.push({ role: msg.is_user ? 'user' : 'assistant', content: msg.text || msg.content }));
    }
    
    const currentUserMessage = { role: 'user', content: userMessage };
    let targetModel = this.model;
    if (base64Image) {
      targetModel = 'llava';
      currentUserMessage.images = [base64Image.includes(',') ? base64Image.split(',')[1] : base64Image];
    }
    ollamaMessages.push(currentUserMessage);

    try {
      const res = await fetch(`${this.baseUrl}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: targetModel, messages: ollamaMessages, stream: false })
      });

      if (!res.ok) throw new Error(`Ollama unreachable at ${this.baseUrl}`);

      const data = await res.json();
      const rawText = data.message?.content || '';
      return { text: this._cleanText(rawText), risk: this._parseRisk(rawText), provider: 'ollama' };
    } catch (err) {
      return { text: `⚠️ AI Offline: ${err.message}. To use AI in the cloud, add GEMINI_API_KEY to your Vercel env.`, risk: 'normal', error: true };
    }
  }

  async analyzeReport(extractedText) {
    const prompt = `You are a medical report analyst. A patient has shared their medical report.
Here is the extracted text from the report:

---
${extractedText}
---

Please:
1. Identify key findings and values
2. Explain what each value means in simple terms
3. Highlight any abnormal values
4. Provide a summary of overall health based on this report
5. Recommend if the patient should see a specialist

Include a risk tag: [RISK:NORMAL], [RISK:CAUTION], or [RISK:URGENT].`;

    return this.chat([], prompt);
  }

  async analyzeSymptoms(symptoms) {
    const prompt = `A patient reports the following symptoms: ${symptoms}

Based on these symptoms:
1. What are the most likely conditions?
2. What additional information would help narrow down the cause?
3. What immediate steps should the patient take?
4. Should they see a doctor urgently?

Include a risk tag: [RISK:NORMAL], [RISK:CAUTION], or [RISK:URGENT].`;

    return this.chat([], prompt);
  }
}

module.exports = new AiService();
