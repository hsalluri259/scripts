#!/opt/app/python3/bin/python3.4
'''
Create a program that asks the user to enter their name and their age. Print out a message addressed to them that tells them the year that they will turn 100 years old.

Extras:

    Add on to the previous program by asking the user for another number and printing out that many copies of the previous message. (Hint: order of operations exists in Python)
    Print out that many copies of the previous message on separate lines.
'''
import datetime
name = input("Enter your name:")
print("Your name is: " + name)
age = int(input("Enter your age: "))
print("Your age is: %d" % age)
year = 100 - age
print("You will turn 100 years old in %d years" % year)
#approach 1
#current_year = int(input("Enter current year:"))
#target = current_year + year
#print("you will be 100 years old in %d" % target)
#approach 2
now = int(datetime.datetime.now().strftime("%Y"))
print(now)
target = now + year
number = int(input("Enter a number to print copies:"))
i=1
while i <= number:
    print("%d) You will be 100 in year %d \n" % (i,target))
    i += 1
#approach 3
#now = datetime.datetime.now()
#target = now.year + year
#print("You will be 100 in year %d" % target)
