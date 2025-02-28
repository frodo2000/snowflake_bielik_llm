from flask import Flask, request, Response, jsonify
from openai import OpenAI
import logging
import os
import re
import json

app = Flask(__name__)
app.logger.setLevel(logging.ERROR)

model = os.getenv("MODEL")
base_url=os.getenv("BIELIK_VLLM_API")

client = OpenAI(
    base_url=base_url,
    api_key="EMPTY",
)

@app.route("/bielik_complete_varchar", methods=['POST'])
def bielik_complete_varchar():
    try:
        request_data: dict = request.get_json(force=True)
        return_data = []

        for index, user_prompt in request_data["data"]:
            completion = client.chat.completions.create(
                model=model,
                messages=[
                    {
                        "role": "user",
                        "content": user_prompt
                    }
                ]
            )

            return_data.append(
                [
                    index,
                    completion.choices[0].message.content
                ]
            )
        
        return jsonify(
            {
                "data": return_data
            }
        )
    except Exception as e:
        app.logger.exception(e)
        return jsonify(str(e)), 500
    
@app.route("/bielik_complete_array", methods=['POST'])
def bielik_complete_array():
    try:
        allowed_options_values = set(['temperature','top_p','max_tokens','response_format'])

        request_data: dict = request.get_json(force=True)
        return_data = []

        for index, messages, options in request_data["data"]:
            if not allowed_options_values.issuperset(options.keys()):
                raise Exception(f"Unsupported param for options provided for bielik_complete. Supported params are {allowed_options_values}")

            #Translate Snowflake response format to OpenAI format
            if 'response_format' in options.keys():
                if options['response_format']['type']=='json':
                    response_format = {'type':'json_object'}
                    extra_body = {
                        'guided_json': options['response_format']['schema']
                    }
                    json_data_expected = True
                else:
                    raise Exception(f"Unsupported value for responseFormat.type provided for bielik_complete. Supported value is json")
            else:
                response_format = None
                extra_body = None
                json_data_expected = False

            completion = client.chat.completions.create(
                model=model,
                messages=messages,
                max_tokens=options['max_tokens'] if 'max_tokens' in options.keys() else 4096,
                temperature=options['temperature'] if 'temperature' in options.keys() else 1,
                top_p=options['top_p'] if 'top_p' in options.keys() else 1,
                response_format=response_format,
                extra_body=extra_body
            )
                    
            if json_data_expected:
                structure_output = []
                for choice in completion.choices:
                    response_text = choice.message.content
                    try:
                        json_dict = json.loads(response_text)
                        json_type = 'json'
                    except Exception:
                        json_dict = {'unparsed_text': response_text}
                        json_type = 'unparsed message'
                    message = {
                        'structured_output':{
                            'raw_message': json_dict,
                            'type': json_type
                        }
                    }
                    structure_output.append(message)

                response={
                    'created':completion.created,
                    'model':completion.model,
                    'structured_output':structure_output,
                    'usage': {
                        'completion_tokens':completion.usage.completion_tokens,
                        'prompt_tokens':completion.usage.prompt_tokens,
                        'total_tokens':completion.usage.total_tokens
                    }
                }
                return_data.append(
                    [
                        index,
                        response
                    ]
                )
            else:
                choices = []
                for choice in completion.choices:
                    element = {
                        'messages':choice.message.content,

                    }
                    choices.append(element)
                response={
                    'choices': choices,
                    'created':completion.created,
                    'model':completion.model,
                    'usage': {
                        'completion_tokens':completion.usage.completion_tokens,
                        'prompt_tokens':completion.usage.prompt_tokens,
                        'total_tokens':completion.usage.total_tokens
                    }
                }

                return_data.append(
                    [
                        index,
                        response
                    ]
                )

        return jsonify(
            {
                "data": return_data
            }
        )
    except Exception as e:
        app.logger.exception(e)
        return jsonify(str(e)), 500
    
if __name__ == '__main__':
   app.run()