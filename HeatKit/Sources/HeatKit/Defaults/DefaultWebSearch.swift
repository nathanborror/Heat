import Foundation

extension Defaults {

    public static let webSearchInstruction = Instruction(
        kind: .prompt,
        instructions: """
            Select relevant website results, scrape their page and summarize it. Use the <search_results> below to select at least 3 results to scrape and summarize. Choose the most relevant and diverse sources that would provide comprehensive information about the search query, "{{query}}". \

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

            Remember to select at least 3 results, but you may choose more if you find additional sources that provide valuable and diverse information. Ensure that your summaries are objective and accurately represent the content of each source.

            <search_results>
            {{results}}
            </search_results
            """
    )
}
