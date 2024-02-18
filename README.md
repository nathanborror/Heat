# Heat

More people need to experience open source LLMs. Heat is an open source native iOS and macOS client for interacting with the most popular LLM services. A sister project, [Swift GenKit](https://github.com/nathanborror/swift-gen-kit), attempts to abstract away all the differences across each service including OpenAI, Mistral, Perplexity, Anthropic and all the models available with [Ollama](https://ollama.ai) which you can run locally.

[![image](https://github.com/nathanborror/Heat/blob/main/Screens/Screens.png?raw=true)](https://github.com/nathanborror/Heat/blob/main/Screens/Screens.png?raw=true)

### Basic Instructions

1. Build and run
2. Navigate to Preferences > Services and provide an access token for services you want to use
3. Choose which model you want to use and be sure the service is selected on the main Preferences screen.

### Ollama Instructions

1. Install [Ollama](https://ollama.ai/download) and pull some [models](https://ollama.ai/library)
2. Run the ollama server `ollama serve`
3. Build and run

To run the iOS app on your device you'll need to figure out what the local IP is for your server. It's usually something like 10.0.0.XXX. Under Preferences > Services > Ollama you can set the IP as long as you stay on your local network. You could conceivably run this on a server somewhere else and access it over any network but I haven't tested that. Sometimes Ollama's default port 11434 doesn't work and you'll need to change it to something like 8080 and run the server manually: `OLLAMA_HOST=0.0.0.0:8080 ollama serve`

### Future

Originally the plan for this project was to get models running on-device — hence the name Heat because your device will heat up! — but that was hard. As this becomes more feasible I will revisit. 