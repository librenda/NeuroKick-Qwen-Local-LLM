# Create a file called test_prompt.json
cat > test_prompt.json << 'EOL'
{
  "model": "qwen3:4b",
  "messages": [
    {
      "role": "system",
      "content": "You are a Workplace Relationship Analyst, an expert in evaluating manager-employee communication. You analyze conversations to identify communication patterns, emotional dynamics, and performance-related issues, providing actionable, work-focused recommendations to enhance leadership, engagement, and productivity."
    },
    {
      "role": "user",
      "content": "Analyze the following workplace conversation between a manager and an employee. Provide a concise report that includes:\n1. **Communication Patterns**: Identify key patterns in tone, clarity, and intent.\n2. **Emotional Dynamics**: Highlight emotional undercurrents and their impact.\n3. **Performance Issues**: Pinpoint issues affecting performance.\n4. **Actionable Recommendations**: Suggest specific strategies for improvement.\n\n[00:31] Mike: \"Abigail, as you know, it's that time of year when we do performance reviews.\"\n[00:33] Abigail: \"Yes, I know.\"\n[00:35] Mike: \"Well, let me get right to the point: your attendance is, quite frankly, just not acceptable. You've been late over a dozen times, you've maxed out all your PTO, and your co-workers say you're often difficult to communicate with.\"\n[00:51] Abigail: \"I've had good reason for being out of the office, and I provided HR with a note from my therapist for the days that I was out.\"\n[00:52] Mike: \"That may be, but on my team everyone has to pull their own weight.\""
    }
  ],
  "stream": false
}
EOL


# Send the request and save the output
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d @test_prompt.json > analysis_result.json


# View the full response
cat analysis_result.json

# Or just the message content
jq '.message.content' analysis_result.json



(base) Mac:NeuroKick-gemma-Local-LLM b432li$ curl -X POST http://localhost:11434/api/chat \
>   -H "Content-Type: application/json" \
>   -d @test_prompt.json > analysis_result.json
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  7575    0  6050  100  1525     40     10  0:02:32  0:02:29  0:00:03  1573