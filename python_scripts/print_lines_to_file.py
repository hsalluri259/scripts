#!/bin/python
#A file_name where it should write the content.
#The content that should go in the file. The script should keep accepting lines of text until the user enters an empty line

def get_file_name(reprompt=False):
    if reprompt:
        print("Please enter file_name: ")
    file_name = raw_input("Enter the file name to write into").strip()
    return file_name or get_file_name(True)
file_name = get_file_name()
print("Please enter your content. Entering an empty line will write the content to %s:\n" % file_name)
with open(file_name, 'w') as f:
    eof = False
    lines = []
    while not eof:
        line = raw_input()
        if line.strip():
            lines.append("%s \n" % line)
        else:
            eof = True
    f.writelines(lines)
    print("Lines written into file: %s" % file_name)    
