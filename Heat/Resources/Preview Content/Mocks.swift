import Foundation
import SharedKit
import GenKit
import HeatKit

let mock_conversation = Conversation(
    instructions: AssistantInstructions
)

let mock_messages: [Message] = [
    .init(
        referenceID: mock_conversation.id.rawValue,
        role: .user,
        content: "Write a report on the latest o1 model release from OpenAI"
    )
]

let mock_run_id = Run.ID.id

let mock_run = Run(
    messages: [
        .init(
            referenceID: mock_conversation.id.rawValue,
            runID: mock_run_id,
            role: .assistant,
            content: """
                To provide you with the most up-to-date and accurate information about OpenAI's latest model \
                release, I'll need to search for the most recent news. Let me do that for you.
                """,
            toolCalls: [
                .init(
                    function: .init(
                        name: Toolbox.searchWeb.name,
                        arguments: """
                            {"query": "OpenAI latest o1 model release", "kind": "news"}
                            """
                    )
                )
            ]
        ),
        .init(
            referenceID: mock_conversation.id.rawValue,
            runID: mock_run_id,
            role: .tool,
            content: """
                Select relevant website results, scrape their page and summarize it. Use the <search_results> below \
                to select at least 3 results to scrape and summarize. Choose the most relevant and diverse sources \
                that would provide comprehensive information about the search query, "OpenAI latest o1 model release". 
                
                Consider factors such as:
                   - Relevance to the search query
                   - Credibility of the source
                   - Diversity of perspectives
                   - Recency of the information

                For each selected result, provide a summary of the key information. Your summary should:
                   - Be concise but informative (aim for 3-5 sentences per result)
                   - Capture the main points relevant to the search query
                   - Avoid unnecessary details or tangential information
                   - Use your own words, do not copy text directly from the sources

                Remember to select at least 3 results, but you may choose more if you find additional sources that \
                provide valuable and diverse information. Ensure that your summaries are objective and accurately \
                represent the content of each source.

                Use the `browse_web` tool.

                <news_search_results>
                    <result>
                        <title>OpenAI releases o1 model with human-like reasoning</title>
                        <url>https://fortune.com/2024/09/12/openai-new-ai-model-strawberry-o1-chatgpt/</url>
                        <description>OpenAI is releasing a new artificial intelligence model known internally as “Strawberry” that can perform some human-like reasoning tasks,...</description>
                    </result>
                    <result>
                        <title>OpenAI releases o1, its first model with ‘reasoning’ abilities</title>
                        <url>https://www.theverge.com/2024/9/12/24242439/openai-o1-model-reasoning-strawberry-chatgpt</url>
                        <description>OpenAI is releasing a new model called o1, the first in a planned series of “reasoning” models that have been trained to answer more complex...</description>
                    </result>
                    <result>
                        <title>Say Hello to OpenAI o1: Preview Release of a New Model Now Available (First in a Series of “Reasoning” Models)</title>
                        <url>https://www.infodocket.com/2024/09/12/say-hello-to-openai-o1-preview-release-of-a-new-model-now-available-first-in-a-series-of-reasoning-models/</url>
                        <description>From OpenAI: We've developed a new series of AI models designed to spend more time thinking before they respond.</description>
                    </result>
                    <result>
                        <title>Introducing o1: OpenAI's new reasoning model series for developers and enterprises on Azure</title>
                        <url>https://azure.microsoft.com/en-us/blog/introducing-o1-openais-new-reasoning-model-series-for-developers-and-enterprises-on-azure/</url>
                        <description>We are excited to add OpenAI's newest models o1-preview and o1-mini to Azure OpenAI Service, Azure AI Studio and GitHub Models. Learn more.</description>
                    </result>
                    <result>
                        <title>Making Logical Sense Of The Newly Launched OpenAI ‘o1’ Model That ‘Thinks’ Longer And Keeps Hidden Its Ace-In-The-Hole Chain-Of-Thought</title>
                        <url>https://www.forbes.com/sites/lanceeliot/2024/09/13/making-logical-sense-of-the-newly-launched-openai-o1-model-that-thinks-longer-and-keeps-hidden-its-ace-in-the-hole-chain-of-thought/</url>
                        <description>OpenAI released a new generative AI model named o1. Lots of hubbub arises. Here's my close look and scoop on what it is all about.</description>
                    </result>
                    <result>
                        <title>ChatGPT o1 is the new 'strawberry' model from OpenAI — 5 prompts to try it out</title>
                        <url>https://www.tomsguide.com/ai/chatgpt/chatgpt-o1-is-the-new-strawberry-model-from-openai-5-prompts-to-try-it-out</url>
                        <description>ChatGPT has been given an o1 upgrade that allows the AI model to reason over a problem before responding.</description>
                    </result>
                    <result>
                        <title>OpenAI unveils o1, a model that can fact-check itself</title>
                        <url>https://techcrunch.com/2024/09/12/openai-unveils-a-model-that-can-fact-check-itself/</url>
                        <description>ChatGPT maker OpenAI has announced its next major product release: A generative AI model code-named Strawberry, officially called OpenAI o1.</description>
                    </result>
                    <result>
                        <title>OpenAI's latest o1 model family tries to emulate 'reasoning' – tho might overthink things a bit</title>
                        <url>https://www.theregister.com/2024/09/13/openai_rolls_out_reasoning_o1/</url>
                        <description>OpenAI on Thursday introduced o1, its latest large language model family, which it claims is capable of emulating complex reasoning.</description>
                    </result>
                    <result>
                        <title>OpenAI’s new o1 models push AI to PhD-level intelligence</title>
                        <url>https://www.fastcompany.com/91189817/openais-new-o1-models-push-ai-to-phd-level-intelligence</url>
                        <description>OpenAI introduced on Thursday OpenAI o1, a new series of large language models the company says are designed for solving difficult problems...</description>
                    </result>
                    <result>
                        <title>OpenAI released o1 series AI models with enhanced reasoning</title>
                        <url>https://www.testingcatalog.com/openai-released-o1-series-ai-models-with-enhanced-reasoning/</url>
                        <description>Discover OpenAI's new o1 AI models, o1-preview and o1-mini, enhancing reasoning in science, coding, and math. Available to ChatGPT Plus...</description>
                    </result>
                </news_search_results>
                """,
            name: Toolbox.browseWeb.name,
            metadata: .init(["label": "Searched web for 'OpenAI latest o1 models'"])
        ),
        .init(
            referenceID: mock_conversation.id.rawValue,
            runID: mock_run_id,
            role: .assistant,
            content: """
                Thank you for providing the search results. I'll now summarize the key information from the most \
                relevant sources to create a comprehensive report on OpenAI's latest o1 model release.
                """,
            toolCalls: [
                .init(
                    function: .init(
                        name: Toolbox.browseWeb.name,
                        arguments: """
                            {"url": "https://www.theverge.com/2024/9/12/24242439/openai-o1-model-reasoning-strawberry-chatgpt", "title": "OpenAI releases o1, its first model with 'reasoning' abilities", "instructions": "Summarize the key information about OpenAI's o1 model release, focusing on its capabilities, features, and significance."}
                            """
                    )
                )
            ]
        ),
        .init(
            referenceID: mock_conversation.id.rawValue,
            runID: mock_run_id,
            role: .tool,
            content: """
                <website>
                    <title>OpenAI releases o1, its first model with 'reasoning' abilities</title>
                    <url>https://www.theverge.com/2024/9/12/24242439/openai-o1-model-reasoning-strawberry-chatgpt</url>
                    <summary>
                        Here are the key points about OpenAI's o1 model release:

                        Capabilities:
                        - o1 is OpenAI's first model with "reasoning" abilities, capable of tackling complex problems like coding, math, and science better than previous models.
                        - It uses a "chain of thought" process to solve problems step-by-step, mimicking human-like reasoning.
                        - O1 scored 83% on a qualifying exam for the International Mathematics Olympiad, compared to only 13% for GPT-4.
                        - It reached the 89th percentile in Codeforces programming competitions.

                        Features:
                        - o1 is being released alongside a smaller, cheaper version called o1-mini.
                        - The model was trained using a new optimization algorithm and dataset tailored specifically for it.
                        - The interface shows the model's step-by-step reasoning process, with phrases like "I'm thinking through" to create a more human-like illusion.

                        Significance:
                        - o1 represents a step towards OpenAI's goal of developing human-like artificial intelligence.
                        - Cracking reasoning is seen as a critical breakthrough for unlocking AI capabilities in areas like medicine and engineering.
                        - However, o1 is still relatively slow, not agent-like, and very expensive for developers to use at $15-$60 per million tokens.
                        - The release of o1 comes as OpenAI reportedly looks to raise funding at a $150 billion valuation, showing the company's ambitions in advanced AI models.
                    </summary>
                </website>
                """,
            name: Toolbox.browseWeb.name,
            metadata: .init(["label": "Browsed 'https://www.theverge.com'"])
        ),
        .init(
            referenceID: mock_conversation.id.rawValue,
            runID: mock_run_id,
            role: .assistant,
            content: """
                Based on the information provided, I'll now write a comprehensive report on OpenAI's latest o1 \
                model release.
                """
        ),
    ]
)
