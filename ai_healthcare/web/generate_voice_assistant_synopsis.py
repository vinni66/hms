from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, Frame, PageTemplate, Image
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.utils import ImageReader
import os

def draw_border(canvas, doc):
    canvas.saveState()
    # 1. Draw Border
    canvas.setStrokeColor(colors.black)
    canvas.setLineWidth(1)
    width, height = A4
    margin = 40 
    canvas.rect(margin, margin, width - 2*margin, height - 2*margin)
    
    # 2. Header/Footer (Outside Border)
    # Only draw on pages with content (page number > 1) because Page 1 is Title Page
    page_num = canvas.getPageNumber()
    
    if page_num > 1:
        canvas.setFont("Times-Bold", 10)
        canvas.setFillColor(colors.black)
        
        # Header: Top Right
        canvas.drawRightString(width - margin, height - margin + 10, "AI VOICE ASSISTANT")
        
        # Footer: Bottom Left -> GM UNIVERSITY DAVANGERE
        canvas.drawString(margin, margin - 20, "GM UNIVERSITY DAVANGERE")
        
        # Footer: Bottom Right -> Page No
        canvas.drawRightString(width - margin, margin - 20, f"Page {page_num}")
    
    canvas.restoreState()

def create_synopsis():
    filename = "Project_Synopsis_Voice_Assistant.pdf"
    doc = SimpleDocTemplate(filename, pagesize=A4,
                            rightMargin=55, leftMargin=55,
                            topMargin=55, bottomMargin=55)
    
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id='normal')
    template = PageTemplate(id='border_page', frames=frame, onPage=draw_border)
    doc.addPageTemplates([template])
    
    styles = getSampleStyleSheet()
    style_normal = styles['Normal']
    
    # Continuous Flow Styling
    style_justify = ParagraphStyle(name='Justify', parent=style_normal, alignment=TA_JUSTIFY, spaceAfter=10, fontSize=12, leading=18, fontName='Times-Roman', textColor=colors.black)
    style_center = ParagraphStyle(name='Center', parent=style_normal, alignment=TA_CENTER, spaceAfter=4, fontSize=12, leading=14, fontName='Times-Roman', textColor=colors.black)
    style_center_bold = ParagraphStyle(name='CenterBold', parent=style_center, fontName='Times-Bold')
    
    style_heading = ParagraphStyle(name='Heading', parent=style_normal, alignment=TA_CENTER, fontSize=14, leading=18, spaceAfter=12, fontName='Times-Bold', textColor=colors.blue)
    
    style_sub_heading = ParagraphStyle(name='SubHeading', parent=style_normal, alignment=TA_LEFT, fontSize=12, leading=16, spaceAfter=10, fontName='Times-Bold', textColor=colors.black)
    style_bullet = ParagraphStyle(name='Bullet', parent=style_justify, bulletIndent=20, leftIndent=30, spaceAfter=8)
    
    style_caption = ParagraphStyle(name='Caption', parent=style_center, fontSize=10, fontName='Times-Bold', spaceAfter=6, spaceBefore=6)

    story = []
    
    # --- PAGE 1: TITLE PAGE ---
    story.append(Spacer(1, 10))
    try:
        # Calculate full width (A4 width - margins) = 595 - 110 = 485
        target_width = 480
        img_check = ImageReader('Picture1.jpg')
        iw, ih = img_check.getSize()
        aspect = ih / float(iw)
        target_height = target_width * aspect
        
        logo = Image('Picture1.jpg', width=target_width, height=target_height)
        logo.hAlign = 'CENTER'
        story.append(logo)
        story.append(Spacer(1, 10))
    except:
        print("Picture1.jpg not found, skipping logo")
        story.append(Spacer(1, 30))
        
    story.append(Paragraph("Project Report on", style_center_bold))
    story.append(Paragraph("“AI-POWERED DESKTOP VOICE ASSISTANT WITH REAL-TIME HOTWORD DETECTION”", ParagraphStyle(name='Title', parent=style_center_bold, fontSize=18, leading=22, spaceAfter=10)))
    story.append(Paragraph("Submitted for the partial fulfilment of the requirement for the completion of the Degree of", style_center_bold))
    
    # BCA Highlight Style
    style_bca = ParagraphStyle(
        name='BCA_Highlight',
        parent=style_center_bold,
        fontSize=16,
        textColor=colors.HexColor("#8B0000"),  # Dark Red
        backColor=colors.HexColor("#D8A0D8"),  # Light Purple / Plum
        borderPadding=10,
        spaceBefore=10,
        spaceAfter=10
    )
    story.append(Paragraph("Bachelor of Computer Applications (BCA)", style_bca))
    story.append(Spacer(1, 30))
    story.append(Paragraph("Project Guide", style_center_bold))
    story.append(Paragraph("Teja H (MCA)", style_center))
    story.append(Paragraph("Assistant Professor", style_center))
    story.append(Spacer(1, 30))
    story.append(Paragraph("(Academic Year 2025-26)", style_center_bold))
    story.append(Spacer(1, 30))
    story.append(Paragraph("Submitted By", style_center_bold))
    story.append(Spacer(1, 10))
    
    story.append(Spacer(1, 10))
    story.append(Paragraph("Table 1: Project Team Members", style_caption))
    
    students = [
        ["1.", "Sushma M V", "U23C01CA061"],
        ["2.", "Vinaya S B", "U23C01CA069"],
        ["3.", "Vinayak M B", "U23C01CA070"]
    ]
    t_students = Table(students, colWidths=[30, 200, 150])
    t_students.setStyle(TableStyle([
        ('FONTNAME', (0,0), (-1,-1), 'Times-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 12),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('TEXTCOLOR', (0,0), (-1,-1), colors.black),
    ]))
    story.append(t_students)
    story.append(Spacer(1, 40))
    
    sig_data = [
        ["________________", "________________", "________________"],
        ["HOD", "Project Guide", "Dean"],
        ["Mrs. Usha N", "Teja H (MCA)", "Dr. Shwetha S Marigoudar"],
        ["MCA, KSET", "Assistant Professor", "B.E, M.Tech (Ph.D)"]
    ]
    t_sigs = Table(sig_data, colWidths=[150, 150, 180])
    t_sigs.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('FONTNAME', (0,0), (-1,-1), 'Times-Bold'),
        ('FONTSIZE', (0,2), (-1,-1), 10),
        ('TOPPADDING', (0,1), (-1,1), 5),
        ('TOPPADDING', (0,2), (-1,-1), 0)
    ]))
    story.append(t_sigs)
    story.append(Spacer(1, 20))
    story.append(Paragraph("SCHOOL OF COMPUTER APPLICATIONS", style_center_bold))
    ptext = '<font size=14><b>FACULTY OF COMPUTING & IT</b></font>'
    story.append(Paragraph(ptext, style_center_bold))
    story.append(Paragraph("GM UNIVERSITY", style_center_bold))
    story.append(Paragraph("Davangere- 577006", style_center_bold))
    story.append(PageBreak())

    # --- PAGE 2: INDEX ---
    story.append(Paragraph("Index", style_heading))
    
    index_data = [
        ["Sl. No.", "Particulars", "Page No."],
        ["1", "Introduction", "3"],
        ["2", "Problem Statement", "3"],
        ["3", "Objective and scope of the project", "4"],
        ["4", "Literature Survey/Related Work", "4"],
        ["5", "Proposed System", "5"],
        ["6", "System Architecture", "5"],
        ["7", "Hardware & Software to be used", "6"],
        ["8", "Conclusion", "7"],
        ["9", "References/Bibliography", "7"]
    ]
    
    t_index = Table(index_data, colWidths=[50, 350, 80])
    t_index.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 1, colors.black),
        ('FONTNAME', (0,0), (-1,0), 'Times-Bold'),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('ALIGN', (1,1), (1,-1), 'LEFT'),
        ('FONTNAME', (0,1), (-1,-1), 'Times-Roman'),
        ('FONTSIZE', (0,0), (-1,-1), 12),
        ('PADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_index)
    story.append(PageBreak())
    
    # --- CONTINUOUS CONTENT ---
    
    def add_section(title, level=1):
        bookmark_name = f"REF_{title}"
        if level == 1:
            story.append(Paragraph(title + f'<a name="{bookmark_name}"/>', style_heading))
        else:
            story.append(Paragraph(title + f'<a name="{bookmark_name}"/>', style_sub_heading))

    # 1. Introduction
    add_section("1. Introduction")
    story.append(Paragraph("<b>The Era of Voice Interaction.</b>", style_justify))
    story.append(Paragraph("The interaction/interface between humans and computers has evolved from command-line interfaces to Graphical User Interfaces (GUIs), and now, to Voice User Interfaces (VUIs). As artificial intelligence technology matures, voice is becoming a primary modality for interaction, offering a hands-free, intuitive way to control digital environments.", style_justify))
    story.append(Paragraph("This project aims to develop a sophisticated Desktop Voice Assistant. Unlike cloud-heavy counterparts, this assistant emphasizes privacy and local processing power where possible. It employs a wake-word detection mechanism (similar to 'Hey Google' or 'Alexa') to listen for commands only when properly addressed, ensuring efficiency and user trust.", style_justify))

    # 2. Problem Statement
    add_section("2. Problem Statement")
    story.append(Paragraph("Despite the prevalence of mobile voice assistants, the desktop environment remains largely dominated by keyboard and mouse inputs.", style_justify))
    story.append(Paragraph("<b>Key Issues Addressed:</b>", style_sub_heading))
    story.append(Paragraph("• <b>Accessibility Barriers:</b> Keyboards and mice are not ideal for users with motor impairments or those who suffer from conditions like Repetitive Strain Injury (RSI). A hands-free control method is essential for inclusive computing.", style_bullet))
    story.append(Paragraph("• <b>Multitasking Inefficiency:</b> Users often need to perform simple tasks (e.g., checking weather, opening apps, setting reminders) while their hands are occupied with other work. Switching contexts to use input devices disrupts workflow.", style_bullet))
    story.append(Paragraph("• <b>Privacy Concerns:</b> Many commercial voice assistants stream audio continuously to the cloud for processing, raising significant privacy concerns. There is a need for a solution that handles the 'Hotword' detection locally.", style_bullet))

    # 3. Objectives and Scope
    story.append(PageBreak())
    add_section("3. Objective and scope of the project")
    story.append(Paragraph("<b>Objectives:</b>", style_sub_heading))
    objs = [
        "To develop a Python-based desktop voice assistant capable of executing system-level commands.",
        "To implement an efficient 'Hotword Detection' engine that listens for a specific wake phrase (e.g., 'Jarvis' or 'Assistant') with low latency.",
        "To integrate Speech-to-Text (STT) for converting user commands into machine-readable text.",
        "To implement Text-to-Speech (TTS) for providing natural, audible feedback to the user.",
        "To automate daily tasks such as launching applications, searching the web, checking time/date, and managing system volume."
    ]
    for o in objs: story.append(Paragraph("• " + o, style_bullet))
    
    story.append(Paragraph("<b>Scope:</b>", style_sub_heading))
    story.append(Paragraph("The project focuses on the Windows desktop environment.", style_justify))
    story.append(Paragraph("<b>In Scope:</b> Hotword detection, speech recognition, command execution (web search, app launch), and audio feedback.", style_justify))
    story.append(Paragraph("<b>Out of Scope:</b> Complex conversational AI (like ChatGPT-level dialogue) is secondary; the primary focus is on functional command execution. Hardware integration (IoT home automation) is not included in this phase.", style_justify))

    # 4. Literature Survey
    story.append(PageBreak())
    add_section("4. Literature Survey/Related Work")
    story.append(Paragraph("Voice recognition technology has a rich history, evolving from pattern matching to deep neural networks.", style_justify))
    
    story.append(Paragraph("<b>[1] Hidden Markov Models (HMMs):</b>", style_sub_heading))
    story.append(Paragraph("Traditionally, speech recognition relied on GMM-HMM systems. While effective for limited vocabularies, they struggled with the variations in natural speech and background noise.", style_justify))
    
    story.append(Paragraph("<b>[2] Deep Learning & End-to-End Models:</b>", style_sub_heading))
    story.append(Paragraph("Recent advancements (e.g., DeepSpeech, Whisper) use Deep Neural Networks (DNNs) to map audio directly to text character-by-character. These models offer superior accuracy but require significant computational resources.", style_justify))
    
    story.append(Paragraph("<b>[3] Hotword Detection Engines:</b>", style_sub_heading))
    story.append(Paragraph("Technologies like Porcupine and Snowboy have revolutionized 'always-listening' systems. They use highly optimized neural networks to detect specific keywords on edge devices (like Raspberry Pis or Desktops) with minimal CPU usage, preserving privacy by not recording until the keyword is heard.", style_justify))
    
    # 5. Proposed System
    add_section("5. Proposed System")
    story.append(Paragraph("The proposed system is a modular application designed for the Windows OS.", style_justify))
    story.append(Paragraph("<b>5.1 Key Features:</b>", style_sub_heading))
    story.append(Paragraph("• <b>Always-Listening Wake Word:</b> The system runs in the background, consuming minimal resources, waiting for the user to say the wake word.", style_bullet))
    story.append(Paragraph("• <b>Natural Language Understanding:</b> The assistant processes commands flexibly (e.g., 'Open Chrome' vs 'Launch Chrome') using basic NLP matching.", style_bullet))
    story.append(Paragraph("• <b>Voice Feedback:</b> The assistant responds verbally, creating a conversational user experience.", style_bullet))
    
    story.append(Paragraph("<b>5.2 Methodology:</b>", style_sub_heading))
    story.append(Paragraph("1. <b>Audio Loop:</b> Continuously capture audio frames from the microphone.", style_bullet))
    story.append(Paragraph("2. <b>Detection:</b> Pass frames to the Hotword Engine. If detected, trigger the main listening mode.", style_bullet))
    story.append(Paragraph("3. <b>Execution:</b> Convert subsequent speech to text, parse the intent, execute the Python function mapping, and speak the result.", style_bullet))

    # 6. System Architecture
    story.append(PageBreak())
    add_section("6. System Architecture")
    story.append(Paragraph("The data flow follows a sequential pipeline:", style_justify))
    steps = [
        "1. <b>User Input:</b> Voice command received via Microphone.",
        "2. <b>VAD & Hotword Engine:</b> Voice Activity Detection filters silence. The Hotword engine checks for the wake phrase.",
        "3. <b>Speech Recognition (STT):</b> Google Speech Recognition or local library (Vosk) converts audio to string.",
        "4. <b>Command Processor:</b> A logic unit compares the string against known command patterns (e.g., 'play music', 'what is the time').",
        "5. <b>Action Handler:</b> Triggers OS-level scripts (subprocess calls, web automation).",
        "6. <b>Response Generator (TTS):</b> Converts the text response back to synthesized speech."
    ]
    style_bullet_tight = ParagraphStyle(name='BulletTight', parent=style_justify, bulletIndent=20, leftIndent=30, spaceAfter=2, leading=12)

    for s in steps: story.append(Paragraph(s, style_bullet_tight))
    
    story.append(Spacer(1, 20))
    story.append(Paragraph("<b>Data Flow Diagram:</b>", style_caption))
    story.append(Paragraph("[Microphone] -> [Wait for Wake Word] -> [Active Listening Mode] -> [Speech-to-Text] -> [Intent Parsing] -> [Execute Function] -> [Text-to-Speech Output]", style_center))

    # 7. Hardware & Software
    add_section("7. Hardware & Software to be used")
    story.append(Paragraph("The project is software-intensive but relies on standard input/output hardware.", style_justify))
    
    # HARDWARE TABLE
    story.append(Paragraph("<b>7.1 Hardware Requirements</b>", style_sub_heading))
    story.append(Paragraph("Table 2: Hardware Requirements", style_caption))
    hw_data = [
        ["Component", "Minimum Requirement", "Recommended Specification"],
        ["Processor", "Intel Core i3", "Intel Core i5 (Quad Core)"],
        ["RAM", "4 GB", "8 GB"],
        ["Input Device", "Built-in Laptop Microphone", "High-Quality USB Condenser Mic"],
        ["Output Device", "Stereo Speakers", "Stereo Speakers / Headset"],
        ["Internet", "2 Mbps (for API calls)", "10 Mbps Fiber (for fast response)"]
    ]
    t_hw = Table(hw_data, colWidths=[120, 160, 180])
    t_hw.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.black),
        ('BACKGROUND', (0,0), (-1,0), colors.navy),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Times-Bold'),
        ('FONTSIZE', (0,0), (-1,0), 10),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('PADDING', (0,0), (-1,-1), 6),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.whitesmoke, colors.white]),
    ]))
    story.append(t_hw)
    story.append(Spacer(1, 12))

    # SOFTWARE TABLE
    story.append(Paragraph("<b>7.2 Software Requirements</b>", style_sub_heading))
    story.append(Paragraph("Table 3: Software Requirements", style_caption))
    sw_data = [
        ["Component", "Specification"],
        ["Operating System", "Windows 10 / 11"],
        ["Programming Language", "Python 3.8+"],
        ["Speech Recognition", "Google Speech API / Vosk / OpenAI Whisper"],
        ["Text-to-Speech", "pyttsx3 (Offline SAPI5 wrapper)"],
        ["Hotword Detection", "Porcupine / Snowboy / Custom Energy Threshold"],
        ["Audio Handling", "PyAudio"],
        ["IDE", "VS Code / PyCharm"]
    ]
    t_sw = Table(sw_data, colWidths=[160, 300])
    t_sw.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.black),
        ('BACKGROUND', (0,0), (-1,0), colors.navy),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Times-Bold'),
        ('FONTSIZE', (0,0), (-1,0), 10),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('PADDING', (0,0), (-1,-1), 6),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.whitesmoke, colors.white]),
    ]))
    story.append(t_sw)

    # 8. Conclusion
    add_section("8. Conclusion")
    story.append(Paragraph("This project successfully bridges the gap between traditional input methods and futuristic voice interaction for desktop environments. By implementing real-time hotword detection, we minimize resource usage and privacy intrusion, creating a solution that is both practical and user-friendly. The assistant empowers users to perform tasks efficiently, proving to be an invaluable tool for productivity and accessibility.", style_justify))
    
    story.append(Paragraph("<b>Future Scope:</b>", style_sub_heading))
    story.append(Paragraph("• <b>IoT Integration:</b> Control smart home lights and fans directly from the desktop.", style_bullet))
    story.append(Paragraph("• <b>Voice Biometrics:</b> Implement speaker identification so the assistant only obeys the authorized user.", style_bullet))
    story.append(Paragraph("• <b>Visual Avatar:</b> Add a 3D interface or holographic representation of the assistant.", style_bullet))

    # 9. References
    add_section("9. References/Bibliography")
    refs = [
        "1.  Python Software Foundation. (2024). Python Language Reference. https://www.python.org",
        "2.  Zhang, Y. et al. (2018). 'DeepSpeech 2: End-to-End Speech Recognition in English and Mandarin'. arXiv preprint.",
        "3.  Picovoice. (2023). Porcupine Wake Word Engine. https://picovoice.ai/porcupine/",
        "4.  Google Cloud. (2024). Speech-to-Text Documentation. https://cloud.google.com/speech-to-text",
        "5.  Jurafsky, D., & Martin, J. H. (2021). Speech and Language Processing. Prentice Hall."
    ]
    for r in refs: story.append(Paragraph(r, style_justify))

    # --- BUILD ---
    doc.multiBuild(story, onFirstPage=draw_border, onLaterPages=draw_border)
    print(f"PDF generated: {filename}")

if __name__ == "__main__":
    create_synopsis()
