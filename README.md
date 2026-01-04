# cwu-breathing-mechanic
<img width="1156" height="722" alt="image" src="https://github.com/user-attachments/assets/915c7cef-f749-4203-baea-3783f50bb6b1" />


A test project where I made my breathing mechanic for my game about sleep paralysis, CAN’T WAKE UP (cwu).

During an in-game paralysis episode, the player has to manually control their breathing by holding and releasing the spacebar at a slow, steady pace. You have to feel the rhythm and stay calm while everything else in the scene is trying to distract or scare you. If the player rushes their breathing, hesitates for too long, or falls out of sync, the system treats it as panic/a fail, and the episode ends badly (i.e. monster jumpscare). The goal is to turn something automatic into something tense and deliberate, forcing the player to stay composed under pressure.

# How to Use 
<sub><span style="color: #888;"><s>since yall couldn't figure it out</s></span></sub>


## Inhaling and Exhaling
> SKRILLEX REFERENCE????

Use the spacebar to inhale and exhale. You can inhale by pressing the spacebar and exhale by releasing. Upon project startup, you will automatically be exhaling (you can see what breathing phase you're currently in by checking the `phase: ` label in the UI. For example, if the spacebar is being pressed at any time, then the label will show `phase: inhale`, as seen below:

<img width="463" height="308" alt="image" src="https://github.com/user-attachments/assets/7c60be9b-0e78-4720-831a-db152d602a93" />

## Timing your Breaths
As mentioned before, you will need to time your breaths correctly. There is a certain amount of time you need to press/release the spacebar for before you switch phases. This amount of time is called the breath interval, and is currently set to `2.5` seconds. When this timer runs out, a new timer starts. This one is called the accuracy gap, and is currently set to `0.7 seconds`. This is the amount of time you have to switch breath phases (i.e. press/release the spacebar). 

<img width="254" height="139" alt="image" src="https://github.com/user-attachments/assets/2c219ced-e49e-4c9d-a9bf-cfffff1791c8" />


Depending on how late/early your input is, the `ACCURACY:` and `AVG:` labels will update accordingly.

<img width="436" height="135" alt="image" src="https://github.com/user-attachments/assets/4e63360b-0c1b-433e-a80b-ffe5e2acd27a" />


## Failing

### Player switches phases too early
If you switch phases before the accuracy gap timer starts (while the breath interval timer is still running), the system will count it as a failure, then skip the accuracy gap timer and automatically start the next breath phase. For example, if the spacebar isn't being pressed (exhaling) and the breath interval timer is at 0.4 seconds, and then the spacebar is pressed, the system will skip to an automatic inhale, disregarding the 0.7-second accuracy gap, and add `+1` to the `FAILS:` counter. An example of this is shown in the clip below. 


https://github.com/user-attachments/assets/dce623e3-b243-48f6-bfca-f2b3d6b60789








<img width="260" height="31" alt="image" src="https://github.com/user-attachments/assets/3dee76a9-c500-4049-adba-e62a0a3dd8d4" />
