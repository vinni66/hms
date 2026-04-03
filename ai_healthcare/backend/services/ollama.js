const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'llama3';

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

class OllamaService {
  constructor() {
    this.baseUrl = OLLAMA_URL;
    this.model = OLLAMA_MODEL;
  }

  async checkHealth() {
    try {
      const res = await fetch(`${this.baseUrl}/api/tags`);
      if (!res.ok) throw new Error('Ollama not reachable');
      const data = await res.json();
      const models = data.models?.map(m => m.name) || [];
      return { status: 'ok', models, activeModel: this.model };
    } catch (err) {
      return { status: 'error', message: `Ollama not running at ${this.baseUrl}. Start it with: ollama serve` };
    }
  }

  // Extract risk level from response text
  _parseRisk(text) {
    if (text.includes('[RISK:URGENT]')) return 'urgent';
    if (text.includes('[RISK:CAUTION]')) return 'caution';
    return 'normal';
  }

  // Remove risk tags from display text
  _cleanText(text) {
    return text
      .replace(/\[RISK:NORMAL\]/gi, '')
      .replace(/\[RISK:CAUTION\]/gi, '')
      .replace(/\[RISK:URGENT\]/gi, '')
      .trim();
  }

  async chat(messages, userMessage, base64Image = null) {
    // Build Ollama message format
    const ollamaMessages = [
      { role: 'system', content: MEDICAL_SYSTEM_PROMPT },
    ];

    // Add conversation history
    if (messages && messages.length > 0) {
      for (const msg of messages) {
        ollamaMessages.push({
          role: msg.role || (msg.is_user ? 'user' : 'assistant'),
          content: msg.text || msg.content,
        });
      }
    }

    // Add current user message
    const currentUserMessage = { role: 'user', content: userMessage };
    
    // Switch to llava if an image is provided
    let targetModel = this.model;
    if (base64Image) {
      targetModel = 'llava';
      // Clean base64 data prefix if present (e.g. data:image/png;base64,)
      const cleanBase64 = base64Image.includes(',') ? base64Image.split(',')[1] : base64Image;
      currentUserMessage.images = [cleanBase64];
    }
    
    ollamaMessages.push(currentUserMessage);

    try {
      const res = await fetch(`${this.baseUrl}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: targetModel,
          messages: ollamaMessages,
          stream: false,
          options: {
            temperature: 0.7,
            top_p: 0.9,
            num_predict: 512,
          },
        }),
      });

      if (!res.ok) {
        const errText = await res.text();
        throw new Error(`Ollama error: ${res.status} — ${errText}`);
      }

      const data = await res.json();
      const rawText = data.message?.content || 'Sorry, I could not process that.';
      const risk = this._parseRisk(rawText);
      const cleanText = this._cleanText(rawText);

      return {
        text: cleanText,
        risk,
        model: data.model,
        tokens: data.eval_count,
      };
    } catch (err) {
      console.error('Ollama chat error:', err.message);
      return {
        text: `⚠️ AI service error: ${err.message}. Make sure Ollama is running with: ollama serve`,
        risk: 'normal',
        error: true,
      };
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

module.exports = new OllamaService();
