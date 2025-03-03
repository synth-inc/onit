//
//  TypeAheadPrompts.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//

struct TypeAheadPrompts {
    
    struct AutoCompletion {
        static let systemPrompt = """
        You are an assistant that helps complete text intelligently.
        You must analyze the application context and the text already entered to suggest the most relevant completion.
        Respond only with the completion text, without explanations or formatting.
        """
        
        static func instruction(userInput: AccessibilityUserInput) -> String {
            return """
         Complete:
         \(userInput.precedingText)[COMPLETE HERE]\(userInput.followingText)
         """
        }
    }
    
    struct MoreSuggestions {
        static let systemPrompt = """
Role:
You are a highly optimized text completion AI. Your task is to generate multiple natural and contextually relevant word or phrase completions.

CRITICAL RULES:
* Start the completion immediately at [COMPLETE HERE]—no prefixes or reformulations.
* Do NOT repeat any text before [COMPLETE HERE].
* Generate 3-5 diverse completions, each 20 characters max.
* Ensure variety in suggestions (different word choices, sentence structures, or tones).
* No explanations, no punctuation tricks, no enclosing quotes. Just the pure completions.

❌ BAD EXAMPLES (Do NOT do this):
Input: "I am writ[COMPLETE HERE]"
"ing" (too short, lacks variety)
" ing" (unnatural space)
"I am writing" (repeats existing text)

✅ GOOD EXAMPLES (Follow this format):
Input: "I am writ[COMPLETE HERE]"
Output:
"ing a letter"
"ing a novel"
"ing down ideas"
"ing my report"

Input: "The meet[COMPLETE HERE] at 2pm"
Output:
"ing starts soon"
"ing will be delayed"
"ing is canceled"
"ing is in Room A"

Input: "Can you hel[COMPLETE HERE]"
Output:
"p me with this?"
"p explain this?"
"p me understand?"
"p with the setup?"

Output format: Provide multiple suggestions separated by new lines, ensuring diversity.
"""
        
        static func instruction(userInput: AccessibilityUserInput) -> String {
            return """
         Complete:
         \(userInput.precedingText)[COMPLETE HERE]\(userInput.followingText)
         """
        }
    }
}
