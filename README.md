<div align="center">
<a href="https://www.getonit.ai">
<img src="macos/Onit/Assets.xcassets/AppIcon.appiconset/onit_appicon_256.png" alt="Onit Logo" width="128" height="128">
</a>
</div>

  
# Onit
Onit is an AI chat sidebar that can dock to any app on your Mac!

It's like Cursor Chat, but for every _other_ app on your computer - not just in your IDE.

## 🚀 Quick Start

- **Download:** Get the pre-built version from [www.getonit.ai](https://www.getonit.ai)
- **Build from source:** Clone this repository and run in Xcode  

## ✨ Features

- **⚡️ Highlight Text → Open Onit:** Onit opens with your selected text ready to use.-

  <div align="center">
	<img src="https://syntheticco.blob.core.windows.net/onit-media/highlighted-text.png" alt="AutoContext Demo" width="800" height="auto">
</div>

- **📖 Load any window as context:** No more copy-pasting. Onit can automatically read your docked window as context.
<div align="center">
	<img src="https://syntheticco.blob.core.windows.net/onit-media/auto-context.png" alt="AutoContext Demo" width="800" height="auto">
</div>
  
- **🎛️ Swap models, not workflows:** Choose whatever model is best suited for the job.

<div align="center">
	<img src="https://syntheticco.blob.core.windows.net/onit-media/provider agnostic.png" alt="AutoContext Demo" width="800" height="auto">
</div>

- **📜 Local Mode:** Toggle Local Mode with a single click to keep everything on your machine.

<div align="center">
	<img src="https://syntheticco.blob.core.windows.net/onit-media/local-mode.png" alt="AutoContext Demo" width="800" height="auto">
</div>

- **⌨️ Customizable Shortcuts:** Choose your hotkey to launch the chat window
	- Default: `Command+0`
  
  

## 🛠️ Technical Details
### Local Mode Setup

1. Download and install [Ollama](https://ollama.com/)
2. Onit will automatically detect your local models through Ollama's API

### Supported Models

- **Remote:**
	- Anthropic (Claude)
	- OpenAI (GPT-4.5, o3)
	- GoogleAI (Gemini 2.5)
	- Perplexity (Sonar, Sonar Deep Research)
	- Deepseek (R1) 
	- xAI (Grok)
	- Custom Providers (OpenRouter, Groq, etc)

- **Local:** Any model supported by Ollama

 
## 📊 Data & Privacy
- Local requests are handled locally.
- When you have added your own tokens, remote requests are sent directly to the providers' APIs.
- When you haven't added your own token, remote requests are redirected through our server. We don't store any of the details of these requests.
- Auto-Context is not uploaded until you hit the 'submit' button.
- Only crash reports are collected (via Firebase) and analytics (via PostHog). You can opt out of both in settings. 

## 💡 Future Roadmap

- [x] Autocontext: Automatically pull context from your computer
- [x] More model providers (Perplexity, Deepseek, etc.)
- [ ] Local-typeahead: Like Cursor Tab, but everywhere
- [ ] Local-RAG: Index and create context from files without uploading
- [ ] Computer Use & Agents
- [ ] Additional platform support (Linux/Windows)
- [ ] Bundled Ollama integration
- [ ] And much more!

## 🎯 Why Onit?

We are building Onit based on these core beliefs:
1. **Universal Access:** AI assistants should be accessible from anywhere on your computer, not just in browsers or specific apps.
2. **Provider Freedom:** Users should have the choice between models and model providers (Anthropic, OpenAI, xAI, etc.) and not be locked into a single provider.
3. **Local First:** AI is _much_ more useful with access to your data. But that doesn't count for much if you have to upload personal files to an untrusted server first. Onit will always provide options for local processing. No personal data will leave your computer without explicit approval.
4. **Customizability:** Onit is your assistant. You should be able to configure it to your liking.
5. **Extensibility:** Onit should allow the community to build and share extensions, making it more useful for everyone.

## 📝 License

Onit is released under a Creative Commons Non-Commercial license. We believe in:
- Open-source transparency
- User customization freedom
- Protection against commercial exploitation


## 💰 Monetization

V2 offers a simple subscription that provides users with access to all the model providers we support through a single, low monthly fee. Details are [here](https://www.getonit.ai/#pricing). If you'd prefer not to use our subscription, you can still access models by adding your own API tokens. 

- Local chat will always remain free
- Source code will remain open for customization

  
## 👥 About Us

We are Synth, Inc., a small team of developers in San Francisco building at the edge of AI progress. Past projects include:
- [Checkbin](https://www.checkbin.dev)
- Alias (deprecated - www.alias.inc)

## 🤝 Contact

We'd love to hear from you! Reach out at contact@getonit.ai

## ❓ FAQ

**Q: Why not Linux or Windows?**
A: We're starting with macOS. Based on reception, we'll expand platform support.

**Q: How can I contribute?**
A: We welcome PRs! Feel free to customize Onit to your needs and share with the community.
