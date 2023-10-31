#!/usr/bin/env python3

calories = open('day_1_input').read().split('\n')
elves = []
active_elf = 0
for entry in calories:
    if entry != '':
        active_elf += int(entry)
    else:
        elves.append(active_elf)
        active_elf = 0

elves.sort(reverse=True)
print(elves[0]+'\n'+elves[0]+elves[1]+elves[2])