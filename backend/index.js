const dotenv = require("dotenv");
dotenv.config();
const express = require("express");
const cors = require("cors");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { Server } = require("socket.io");
const http = require("http");


const app = express();

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: ["http://localhost:3000","http://localhost:5000", "http://192.168.1.155:51251", "http://192.168.1.155:51251","http://localhost:51251"] }
});


app.use(cors({
  origin: ["http://localhost:3000","http://localhost:5000", "http://192.168.1.155:51251", "http://192.168.1.155:51251","http://localhost:51251"] // React dev server
}));


app.use(express.json());
const PORT = process.env.PORT || 3001;

// Initialize Gemini only when needed
let gemini = null;
const initializeGemini = () => {
  if (!gemini && process.env.GOOGLE_API_KEY) {
    gemini = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
  }
  return gemini;
};


// Demo responses for when OpenAI is not available
const getDemoResponse = (message) => {
  const responses = [
    `You asked about: "${message}". This is a demo response since OpenAI API is not available.`,
    `Interesting question about "${message}". I'm running in demo mode right now.`,
    `Thanks for your message: "${message}". Please add OpenAI credits for full AI responses.`,
    `I see you mentioned: "${message}". This is a fallback response while OpenAI is unavailable.`
  ];
  
  // Simple keyword-based responses
  const lowerMessage = message.toLowerCase();
  if (lowerMessage.includes('hello') || lowerMessage.includes('hi') || lowerMessage.includes('สวัสดี')) {
    return 'Hello! I\'m currently running in demo mode. How can I help you today?';
  }
  if (lowerMessage.includes('how are you')) {
    return 'I\'m doing well, thank you! I\'m running in demo mode right now.';
  }
  if (lowerMessage.includes('weather')) {
    return 'I can\'t check the weather in demo mode, but I hope it\'s nice where you are!';
  }
  
  return responses[Math.floor(Math.random() * responses.length)];
};


// Replace your /chat route with this improved version
app.post("/chat", async (req, res) => {
  try {
    const { message, mode } = req.body;
    
    // Better validation
    if (!message) {
      return res.status(400).json({ 
        error: "Message is required",
        details: "Request body must include a 'message' field"
      });
    }
    
    if (typeof message !== 'string') {
      return res.status(400).json({ 
        error: "Message must be a string",
        details: "Received message type: " + typeof message
      });
    }
    
    if (message.trim() === "") {
      return res.status(400).json({ 
        error: "Message cannot be empty",
        details: "Message content cannot be only whitespace"
      });
    }

    // Log the incoming request for debugging
    console.log(`Chat request - Mode: ${mode}, Message length: ${message.length}`);

    // --- Select mode based on client request ---
    if (mode === "gemini") {
      const geminiClient = initializeGemini();
      if (geminiClient) {
        try {
          const model = geminiClient.getGenerativeModel({ model: "gemini-2.0-flash" });
          const result = await model.generateContent(message);
          const text = result.response.candidates[0]?.content?.parts[0]?.text || "No response";
          return res.json({ reply: text, mode: "gemini" });
        } catch (err) {
          console.error("Gemini Error:", err.message);
          // Don't return here, let it fall through to demo mode
        }
      }
    }

    if (mode === "gpt") {
      try {
        const OpenAI = require("openai");
        const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
        
        if (process.env.OPENAI_API_KEY) {
          const response = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [{ role: "user", content: message }],
            max_tokens: 150,
          });
          const reply = response.choices[0].message.content;
          return res.json({ reply, mode: "openai" });
        }
      } catch (err) {
        console.error("OpenAI Error:", err.message);
        // Don't return here, let it fall through to demo mode
      }
    }

    // Fallback to demo mode
    const demoResponse = getDemoResponse(message);
    return res.json({
      reply: demoResponse,
      mode: "demo",
      note: "Running in demo mode (no valid API key or mode error)"
    });

  } catch (error) {
    console.error("Chat Error:", error);
    res.status(500).json({ 
      error: "Internal server error",
      details: error.message 
    });
  }
});


server.listen(PORT, () => {
  console.log(`Backend running on port ${PORT}`);
  console.log(`- Gemini configured: ${!!process.env.GOOGLE_API_KEY}`);
  console.log(`- OpenAI configured: ${!!process.env.OPENAI_API_KEY}`);
  if (!process.env.GOOGLE_API_KEY && !process.env.OPENAI_API_KEY) {
    console.log("Note: Running in DEMO mode. Add an API key to your .env file.");
  }
});