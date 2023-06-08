import pandoc

in_file = open("example.md", "r").read()
pandoc.write(in_file, file="example.pdf", format="pdf")
Or maybe you'd like to convert the markdown file to a json object. You can use the following script to do so:

python
import pandoc
md_string = """
# Hello from Markdown

**This is a markdown string**
"""
input_string = pandoc.read(md_string)
pandoc.write(input_string, format="json", file="md.json")