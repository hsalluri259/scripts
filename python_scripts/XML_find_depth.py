import xml.etree.ElementTree as etree
maxdepth = 0
def depth(elem, level):
    global maxdepth
    # your code goes here
    if (level == maxdepth):
        maxdepth += 1
        
    for child in elem:
        depth(child, level + 1)
 """You are given a valid XML document, and you have to print the maximum level of nesting in it. Take the depth of the root as 0.

Input Format

The first line contains , the number of lines in the XML document.
The next lines follow containing the XML document.

Output Format

Output a single line, the integer value of the maximum level of nesting in the XML document."""   
     
