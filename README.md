# Heat

More people need to experience open source LLMs. Heat is an [Ollama](https://ollama.ai) desktop and mobile client.

[![image](https://github.com/nathanborror/Heat/blob/main/Screens/Screens.png?raw=true)](https://github.com/nathanborror/Heat/blob/main/Screens/Screens.png?raw=true)

### Instructions

1. Install [Ollama](https://ollama.ai/download) and pull some [models](https://ollama.ai/library).
2. Run the ollama server on port 8080 `OLLAMA_HOST=0.0.0.0:8080 ollama serve`.
3. Build and run this Xcode project.

To run the iOS app on your device you'll need to figure out what the local IP is for your server. It's usually something like 10.0.0.123. You can set the IP under Settings and use ollama as long as you stay on your local network. You could conceivably run this on a server somewhere else and access it over any network but I haven't tested that.

### Plans

Plans are to add support for the rest of the Ollama API and figure out how to run the Ollama go package as an embedded framework so we can run models locally on devices like iPhones or iPads.

*Heat, because it's gonna make your devices hot!*