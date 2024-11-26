<h1 align="center">Sidekick</h1>

Chat with an local LLM that can respond with information from your files, folders and websites on your Mac without installing any other software. All conversations happen offline, and your data is saved locally.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/demoScreenshot.png)

- Try any llama.cpp compatible GGUF model
- Customize model behaviour by setting up profiles with a custom system prompt
- Associate resources (files, folders and websites) to a profile to allow RAG (Retrieval Augmentented Generation)
- Optionally use [Tavily](https://tavily.com/) to allow up to date responses with information from web search

## Table of Contents  
- [Example Use](#example_use)  
- [Features](#features)
- [Installation](#installation)
- [Goals](#goals)
- [Contributing](#contributing)
- [Contact](#contact)
- [Credits](#credits)  

<a name="example_use"/>

## Example Use

Let’s say you're collecting evidence for a History paper about interactions between Aztecs and Spanish troops, and you’re looking for text about whether the Aztecs used captured Spanish weapons.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/demoHistoryScreenshot.png)

Here, you can ask Sidekick, “Did the Aztecs use captured Spanish weapons?”, and it responds with direct quotes with page numbers and a brief analysis.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/demoHistorySource.png)

To verify Sidekick’s answer, just click on the references displayed below Sidekick’s answer, and the academic paper referenced by Sidekick immediately opens in your viewer.

<a name="features"/>
## Features

### Resource Use

Sidekick accesses files, folders, and websites from your profiles, which can be individually configured to contain resources related to specific areas of interest. Activating a profile allows Sidekick to access the relevant information.

For example, a student might create the profiles `English Literature`, `Mathematics`, `Geography`, `Computer Science` and `Physics`. In the image below, he has activated the profile `Computer Science`, allowing Sidekick to reply with information from that profile.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/demoProfileUse.png)

Users can also give Sidekick access to files just by dragging them into the input field.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/demoTemporaryResource.png)

Sidekick can even respond with the latest information using **web search**, speeding up research.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/webSearch.png)

### Inline Writing Assistant

Press `Command + Control + I` to access Sidekick's inline writing assistant. For example, use the `Answer Question` command to do your homework without leaving Microsoft Word!

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/inlineWritingAssistant.png)

### Advanced Markdown Rendering

Markdown in rendered beautifully in Sidekick.

#### LaTeX

Sidekick offers native LaTeX rendering for mathematical equations.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/latexRendering1.png)

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/latexRendering2.png)

#### Data Visualization

Visualizations are automatically provided for tables when appropriate, with a variety of charts availible, including bar charts, line charts and pie charts.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/dataVisualization1.png)

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/dataVisualization2.png)

#### Code

Code is beautifully rendered with syntax highlighting, and can be exported or copied at the click of a button.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/codeExport.png)

### Fast Generation

Sidekick uses `llama.cpp` as its inference backend, which is optimized to deliver lightning fast generation speeds on Apple Silicon. Sidekick also supports speculative decoding, which can increase performance by up to 51%.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/speculativeDecodingSupport.png)

Optionally, offload generation to your desktop to speed up generation while extending the battery life of your MacBook.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/README%20Images/serverUse.png)

<a name="installation"/>
## Installation

**Requirements**
- A Mac with Apple Silicon
- RAM ≥ 8 GB

**Prebuilt Package**
- Download the packages from [Releases](https://github.com/johnbean393/Sidekick/releases/), and open it. Note that since the package is not notarized, you will need to enable it in System Settings. 

**Build it yourself**
- Download, open in Xcode, and build it.

<a name="goals"/>
## Goals

The main goal of Sidekick is to make open, local, private models accessible to more people, and allow a local model to gain context of select files, folders and websites.

Sidekick is a native LLM application for macOS that runs completely locally. Download it and ask your LLM a question without doing any configuration. Give the LLM access to your folders, files and websites with just 1 click, allowing them to reply with context.

- No config. Usable by people who haven't heard of models, prompts, or LLMs.
- Performance and simplicity over developer experience or features. Notes not Word, Swift not Electron.
- Local first. Core functionality should not require an internet connection.
- No conversation tracking. Talk about whatever you want with Sidekick, just like Notes.
- Open source. What's the point of running local AI if you can't audit that it's actually running locally?
- Context aware. Aware of your files, folders and content on the web. 

<a name="contributing"/>
## Contributing

Contributions are very welcome. Let's make Sidekick simple and powerful.

<a name="contact"/>
## Contact

Contact this repository's owner at johnbean393@gmail.com, or file an issue.

<a name="credits"/>
## Credits

This project would not be possible without the hard work of:

- psugihara and contributors who built [FreeChat](https://github.com/psugihara/FreeChat), which this project took heavy inspiration from
- Georgi Gerganov for [llama.cpp](https://github.com/ggerganov/llama.cpp)
- Meta for training Llama 3.1
- Google for training Gemma 2
