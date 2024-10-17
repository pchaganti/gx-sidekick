<h1 align="center">Sidekick</h1>

Chat with an LLM with RAG (Retrieval Augmentented Generation) on your Mac without installing any other software. All conversations happen offline, and your data is saved locally.

- Try any llama.cpp compatible GGUF model
- Customize model behaviour by setting up profiles with a custom system prompt
- Associate resources (files, folders and websites) to a profile to allow RAG (Retrieval Augmentented Generation)
- Optionally use [Tavily](https://tavily.com/) to allow up to date responses with information from web search

## Installation

**Requirements**
- An Apple Silicon Mac
- RAM ≥ 8 GB

<!--**Prebuilt Package**-->
<!--- Download the packages from [Releases](https://github.com/johnbean393/Sidekick/releases), and open it. Note that since the package is not notarized, you will need to enable it in System Settings. -->

**Build it yourself**
- Download, open in Xcode, and build it.

## Goals

The main goal of Sidekick is to make open, local, private models accessible to more people, and allow a local model to gain context of select files, folders and websites.

Sidekick is a native LLM application for macOS that runs completely locally. Download it and ask your LLM a question without doing any configuration. Give the LLM access to your folders, files and websites with just 1 click, allowing them to reply with context.

- No config. Usable by people who haven't heard of models, prompts, or LLMs.
- Performance and simplicity over developer experience or features. Notes not Word, Swift not Electron.
- Local first. Core functionality should not require an internet connection.
- No conversation tracking. Talk about whatever you want with Sidekick, just like Notes.
- Open source. What's the point of running local AI if you can't audit that it's actually running locally?
- Context aware. Aware of your files, folders and content on the web. 

### Contributing

Contributions are very welcome. Let's make Sidekick simple and powerful.

### Credits

This project would not be possible without the hard work of:

- psugihara and contributors who built [FreeChat](https://github.com/psugihara/FreeChat), which this project took heavy inspiration from
- Georgi Gerganov for [llama.cpp](https://github.com/ggerganov/llama.cpp)
- Meta for training Llama 3.1
- Google for training Gemma 2
