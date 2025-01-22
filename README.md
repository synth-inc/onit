<div align="center">
  <a href="https://www.getonit.ai">
    <img src="macos/Onit/Assets.xcassets/AppIcon.appiconset/app_icon_1x.png" alt="Onit Logo" width="128" height="128">
  </a>
</div>

# Onit

Onit is an open-source AI chat assistant that lives in your desktop. It's ChatGPT Desktop, but with local mode and multi-provider support. It's also Cursor Chat, but not just in your IDE. 

## 🚀 Quick Start

- **Download:** Get the pre-built version from [www.getonit.ai](https://www.getonit.ai)
- **Build from source:** Clone this repository and run in Xcode

## 🎯 Why Onit?

We are building Onit based on these core beliefs:

1. **Universal Access:** AI assistants should be accessible from anywhere on your computer, not just in browsers or specific apps.
2. **Provider Freedom:** Users should have the choice between models and model providers (Anthropic, OpenAI, xAI, etc.) and not be locked into a single provider.
3. **Local First:** AI is _much_ more useful with access to your data. But that doesn't count for much if you have to upload personal files to an untrusted server first. Onit will always provide options for local processing. No personal data will leave your computer without explicit approval. 
4. **Customizability:** Onit is your assistant. You should be able to configure it to your liking.
5. **Extensibility:** Onit should allow the community to build and share extensions, making it more useful for everyone. 

## ✨ Features

- **🤖 Local Mode:** Chat with any model running locally on Ollama - no internet required
- **🔄 Multi-Provider Support:** Toggle between top models from OpenAI, Anthropic, and xAI
- **📜 History:** Access previous chats through history view or up/down arrow shortcuts
- **⌨️ Customizable Shortcuts:** Choose your hotkey to launch the chat window
  - Default: `Command+U`
  - Incognito: `Command+Shift+U`
- **📎 File Upload:** Add context through images or files (with drag & drop support)

## 🛠️ Technical Details

### Local Mode Setup
1. Download and install [Ollama](https://ollama.com/)
2. Onit will automatically detect your local models through Ollama's API

### Supported Models
- **Remote:**
  - Anthropic (Claude)
  - OpenAI (GPT-4, GPT-3.5)
  - xAI (Grok)
- **Local:** Any model supported by Ollama

## 📊 Data & Privacy

- No server component in V1
- Local requests are handled locally
- Remote requests go directly to model providers' APIs
- Only crash reports are collected (via Firebase)

## 💡 Future Roadmap

- [ ] Autocontext: Automatically pull context from your computer
- [ ] Local-RAG: Index and create context from files without uploading
- [ ] Local-typeahead: Like Cursor Tab, but everywhere
- [ ] Additional platform support (Linux/Windows)
- [ ] More model providers (Mistral, Deepseek, etc.)
- [ ] Bundled Ollama integration
- [ ] And much more!

## 📝 License

Onit V1 is released under a Creative Commons Non-Commercial license. We believe in:
- Open-source transparency
- User customization freedom
- Protection against commercial exploitation

## 💰 Monetization

V1 is completely free. Future versions may include paid premium features, but:
- Local chat will always remain free
- Source code will remain open for customization

## 👥 About Us

We are Synth, Inc., a small team of developers in San Francisco building at the edge of AI progress. Other projects include:
- [Checkbin](https://www.checkbin.dev)
- Alias (deprecated - www.alias.inc)

## 🤝 Contact

We'd love to hear from you! Reach out at contact@getonit.ai

## ❓ FAQ

**Q: Why not Linux or Windows?**  
A: We're starting with macOS. Based on reception, we'll expand platform support.

**Q: How can I contribute?**  
A: We welcome PRs! Feel free to customize Onit to your needs and share with the community.
