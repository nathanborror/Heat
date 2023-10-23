# Heat

Heat is a desktop and mobile client to be used with [Ollama](https://ollama.ai). To get it working follow these simple steps:

1. Download and install [Ollama](https://ollama.ai/download).
2. Pull a model from [this list](https://ollama.ai/library) using the `ollama pull <MODEL_NAME>` command.
3. Run the ollama server on port 8080 `OLLAMA_HOST=0.0.0.0:8080 ollama serve`.
4. Build the iOS or macOS app

Plans are to add support for the rest of the Ollama API and figure out how to run the Ollama go package as an embedded framework so we can run models locally on devices like iPhones or iPads.