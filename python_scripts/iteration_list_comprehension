#!/bin/python
import argparse
### Advanced Iteration with List Comprehensions

parser = argparse.ArgumentParser(description='Search for words including partial word')
parser.add_argument('snippet', help='Partial (or Complete) string to search for in the words file')

args = parser.parse_args()
snippet = args.snippet.lower()

words = open('/usr/share/dict/words').readlines()
##replacing all lines with a single statement
print([word for word in words if snippet in word.lower()])
#matches = []

#for word in words:
  #  if snippet in word.lower():
   #     matches.append(word)
#print(matches)
