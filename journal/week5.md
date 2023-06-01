# Week 5 — DynamoDB and Serverless Caching
Hi guys! Welcome back to week 5!! It getting hotter in the kitchen but lets learn about a few definitions today.
This week will be learning about NoSQl Databases and the different types that exist.
- Then we will learn about NoSQL database in AWS which is DynamoDB. So lets start!!

 
## Introduction
**What is NoSQL**
- A flexible document management system for key-value,document, tabular and graphs.
- Non-relational, distributed and scalable. and partition tolerant and 

**Why use NoSQL?**
- Application Development Productivity.
- Large scale data
- They mainatin perfomance no matter the scale of  

**What are the characteristics of NoSQL databases?**
- Non-relational
- Distributed system that can manage large scale data while maintaining high throughput and availability.
- Scalable

**What are the differences between Non-Relational vs Relational Databases?**
| ---Non-Relational Databases---  | ---Relational Databases |
- NOT ONLY tables with fixed columns and rows vs Tables with fixed columns and rows
- Flexible schema vs Fixed Schema
- Scales out(horizontally scaling) vs Scales up(vertical scaling)

**What are the types of NoSQL database types?**
- key-value,
- document, 
- tabular and 
- graphs
- Multi-model type

## Prerequisites



## Business Use Cases
1. Will be used with our application for message caching
2. To create Amazon DynamoDB table for developers to use for their Web Application in AWS to allow for ***uninterrupted flow for a large amount of traffic in microseconds.***
3. For ***milli-second response times***, we add a Amazon DynamoDB Accelerator (DAX) to improve the response time of the DynamoDB tables that has been linked to the Web Application in AWS.

## Tasks
- Have a lecture about data modeling (Single Table Design) for NoSQL
- Launch DynamoDB local
- Seed our DynamoDB tables with data using Faker
- Write AWS SDK code for DynamoDB to query and scan put-item, for predefined endpoints
- Create a production DynamoDB table
- Update our backend app to use the production DynamoDB
- Add a caching layer using Momento Severless Cache

## A lecture about data modeling (Single Table Design) for NoSQL
**Step 1 - DynamoDB Data Modelling Youtube video**
A flat table as we do not have joins as is the case with Relational databases.
NoSQL workbench

**DynamoDB Data Modelling**

It is better to put similar items in the same table/ reduces complexity in the application
Global tables
Sort keys?

***Access Patterns***
1. **A single conversation within the DM** - Determines the habit that a user will most likely use i.e to view messages in the dms, sort messages in descending order and only for the messages with the 2 users.
2. **List of Conversations(all dms)** - 
3. **Create a message** - 
4. **Update message for the last message group** - 


What are primary keys?
What are partition keys?
What are base tables?
What is a GSI?-Global Secondary Index
What are LSI? Local Secondary Indexes
GSI vs LSI?
4kb in read 1kb in writes.

**Advantages of DynamoDB**
- Fast
- Consistent perfomance
- Easily Scalable 


### Launch DynamoDB local
**Step 2 - Start up DynamoDB locally**
- In the backend-flask directory, install Boto3(the AWS python SDK) in our backend by pasting line 2 into ```requirements.txt``` and running line 3:
``` 
cd backend-flask/
boto3
pip install -r requirements.txt
```

- Run ```Docker-compose up``` to start up Dynamo-db local.
- In the existing ```bin``` directory, create a new folder named ```db``` and move all the db script files except for the rds script file.
- In the existing ```bin``` directory, create a new folder named ```rds``` and move the remaining rds script file.

**Common PostgreSQL commands**
```
\x on -- expanded display when looking at data
\q -- Quit PSQL
\l -- List all databases
\c database_name -- Connect to a specific database
\dt -- List all tables in the current database
\d table_name -- Describe a specific table
\du -- List all users and their roles
\dn -- List all schemas in the current database
CREATE DATABASE database_name; -- Create a new database
DROP DATABASE database_name; -- Delete a database
CREATE TABLE table_name (column1 datatype1, column2 datatype2, ...); -- Create a new table
DROP TABLE table_name; -- Delete a table
SELECT column1, column2, ... FROM table_name WHERE condition; -- Select data from a table
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...); -- Insert data into a table
UPDATE table_name SET column1 = value1, column2 = value2, ... WHERE condition; -- Update data in a table
DELETE FROM table_name WHERE condition; -- Delete data from a table
```

### Seed our DynamoDB tables with data using Faker
**Step 3 -  Creating Schema-load Bash Script**
- In the existing ```bin``` directory, create a new folder named ```ddb```.
- In Dynamodb, we create tables instead of databases. Therefore one of the scripts will be, ```schema-load```, ```seed```, ```drop```.

- We will then paste into the schema-load script:
```
#! /usr/bin/env python3 

import boto3
import sys 

attrs = ('endpoint_url': 'hhtp://l;ocalhost:8000')

if len(sys.argv) == 2:
 if "prod" in sysy.argv[1]:
  attrs = {}

ddb = boto3.client('dynamodb', ""attrs )

table_name = 'cruddur-messages'

response = ddb.create_table(
    TableName='string',
    AttributeDefinitions=[
        {
            'AttributeName': 'pk',
            'AttributeType': 'S'
        },
        {
            'AttributeName': 'sk',
            'AttributeType': 'S'
        },
    ],
    KeySchema=[
        {
            'AttributeName': 'pk',
            'KeyType': 'HASH'
        },
        {
            'AttributeName': 'sk',
            'KeyType': 'RANGE'
        },      
    ],
    
    #GlobalSecondaryIndexes=[
     #      ],
    BillingMode='PROVISIONED',
    ProvisionedThroughput={
        'ReadCapacityUnits': 5,
        'WriteCapacityUnits': 5
    },
    
)

print(response)
```

- Change the permissions of the schema-load bash script file by running, in the terminal:
```chmod u+x bin/ddb/schema-load```

- Make sure that dynamodb local is running by making sure it is not commented out in the Docker-compose file then start up Docker-compose again. 
- Run in the terminal ```./bin/ddb/schema-load```

**Step 4 -  Creating List-tables Bash Script**
- In the ddb folder, create a new file named ``list-tables`` to list our tables:
```
#! /usr/bin/env python3 
set -e #stop if it fails at any point

if [ "$1" = "prod" ]; then
  ENDPOINT_URL=""
else
  ENDPOINT_URL="--endpoint=https://local:8000"
 fi

aws dynamodb list-tables $ENDPOINT_URL \  --query TableNames --output table
```

- Change the permissions of the list-tables bash script file, then running in the terminal:
```
chmod u+x bin/ddb/list-tables
./bin/ddb/list-tables
``` 

**Step 5 -  Creating Drop-tables Bash Script**
-  In the ddb folder, create a new file named ``drop-tables`` to drop our tables:
```
#! /usr/bin/bash 

set -e #stop if it fails at any point

if [ -z "$1" ]; then
  echo "NO TABLE_NAME argument supplied e.g # ./bin/ddb/drop cruddur-messages prod "
  exit 1
  TABLE_NAME=$1
fi   

if [ "$1" = "prod" ]; then
  ENDPOINT_URL=""
else
  ENDPOINT_URL="--endpoint=https://local:8000"
 fi

aws dynamodb delete-tables $ENDPOINT_URL \  
--table-name "TABLE_NAME" 
```

- Change the permissions of the list-tables bash script file by running, in the terminal:
```
chmod u+x bin/ddb/drop-tables
./bin/ddb/drop-tables
```

**Step 6 -  Creating Drop-tables Bash Script**
-  In the ddb folder, create a new file named ``seed`` to seed/put data into our tables:
```
#! /usr/bin/env python3

import boto3
import os
import sys
from datetime import datetime, timedata, timezone
import uuid

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..'))
sys.path.append(parent_path)
from lib.db import db

attrs = {
  'endpoint_url': 'http://localhost:8000'
}
# unset endpoint url for use with production database
if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}
ddb = boto3.client('dynamodb',**attrs)

def get_user_uuids():
  sql = """
    SELECT 
      users.uuid,
      users.display_name,
      users.handle
    FROM users
    WHERE
      users.handle IN(
        %(my_handle)s,
        %(other_handle)s
        )
  """
users = db.query_array_json(sql,{
   'my_handle':  'andrewbrown',
   'other_handle': 'bayko'
 })
 my_user    = next((item for item in users if item["handle"] == 'andrewbrown'), None)
 other_user = next((item for item in users if item["handle"] == 'bayko'), None)
 results = {
   'my_user': my_user,
   'other_user': other_user
 }
 print('get_user_uuids')
 print(results)
 return results

def create_message_group(client,message_group_uuid, my_user_uuid, last_message_at=None, message=None, other_user_uuid=None, other_user_display_name=None, other_user_handle=None):
  table_name = 'cruddur-messages'
  record = {
    'pk':   {'S': f"GRP#{my_user_uuid}"},
    'sk':   {'S': last_message_at},
    'message_group_uuid': {'S': message_group_uuid},
    'message':  {'S': message},
    'user_uuid': {'S': other_user_uuid},
    'user_display_name': {'S': other_user_display_name},
    'user_handle': {'S': other_user_handle}
  }

  response = client.put_item(
    TableName=table_name,
    Item=record
  )
  print(response)

def create_message(client,message_group_uuid, created_at, message, my_user_uuid, my_user_display_name, my_user_handle):
  table_name = 'cruddur-messages'
  # Entity # Message Group Id
  record = {
    'pk':   {'S': f"MSG#{message_group_uuid}"},
    'sk':   {'S': created_at },
    'message_uuid': { 'S': str(uuid.uuid4()) },
    'message': {'S': message},
    'user_uuid': {'S': my_user_uuid},
    'user_display_name': {'S': my_user_display_name},
    'user_handle': {'S': my_user_handle}
  }
  # insert the record into the table
    response = client.put_item(
    TableName=table_name,
    Item=record
  )
  # print the response
  print(response)

def create_message_group(client,message_group_uuid, my_user_uuid, last_message_at=None, message=None, other_user_uuid=None, other_user_display_name=None, other_user_handle=None):
  print("")

message_group_uuid = "5ae290ed-55d1-47a0-bc6d-fe2bc2700399" 
time.now(timezone.utc).astimezone()
users = get_user_uuid()

create_message_group(
  client=ddb,
  message_group_uuid=message_group_uuid,
  my_user_uuid=users['my_user']['uuid'],
  other_user_uuid=users['other_user']['uuid'],
  other_user_handle=users['other_user']['handle'],
  other_user_display_name=users['other_user']['display_name'],
  last_message_at=now.isoformat(),
  message="this is a filler message"
)

create_message_group(
  client=ddb,
  message_group_uuid=message_group_uuid,
  my_user_uuid=users['other_user']['uuid'],
  other_user_uuid=users['my_user']['uuid'],
  other_user_handle=users['my_user']['handle'],
  other_user_display_name=users['my_user']['display_name'],
  last_message_at=now.isoformat(),
  message="this is a filler message"
)

conversation = """
Person 1: Have you ever watched Babylon 5? It's one of my favorite TV shows!
Person 2: Yes, I have! I love it too. What's your favorite season?
Person 1: I think my favorite season has to be season 3. So many great episodes, like "Severed Dreams" and "War Without End."
Person 2: Yeah, season 3 was amazing! I also loved season 4, especially with the Shadow War heating up and the introduction of the White Star.
Person 1: Agreed, season 4 was really great as well. I was so glad they got to wrap up the storylines with the Shadows and the Vorlons in that season.
Person 2: Definitely. What about your favorite character? Mine is probably Londo Mollari.
Person 1: Londo is great! My favorite character is probably G'Kar. I loved his character development throughout the series.
Person 2: G'Kar was definitely a standout character. I also really liked Delenn's character arc and how she grew throughout the series.
Person 1: Delenn was amazing too, especially with her role in the Minbari Civil War and her relationship with Sheridan. Speaking of which, what did you think of the Sheridan character?
Person 2: I thought Sheridan was a great protagonist. He was a strong leader and had a lot of integrity. And his relationship with Delenn was so well-done.
Person 1: I totally agree! I also really liked the dynamic between Garibaldi and Bester. Those two had some great scenes together.
Person 2: Yes! Their interactions were always so intense and intriguing. And speaking of intense scenes, what did you think of the episode "Intersections in Real Time"?
Person 1: Oh man, that episode was intense. It was so well-done, but I could barely watch it. It was just too much.
Person 2: Yeah, it was definitely hard to watch. But it was also one of the best episodes of the series in my opinion.
Person 1: Absolutely. Babylon 5 had so many great episodes like that. Do you have a favorite standalone episode?
Person 2: Hmm, that's a tough one. I really loved "The Coming of Shadows" in season 2, but "A Voice in the Wilderness" in season 1 was also great. What about you?
Person 1: I think my favorite standalone episode might be "The Long Twilight Struggle" in season 2. It had some great moments with G'Kar and Londo.
Person 2: Yes, "The Long Twilight Struggle" was definitely a standout episode. Babylon 5 really had so many great episodes and moments throughout its run.
Person 1: Definitely. It's a shame it ended after only five seasons, but I'm glad we got the closure we did with the series finale.
Person 2: Yeah, the series finale was really well-done. It tied up a lot of loose ends and left us with a great sense of closure.
Person 1: It really did. Overall, Babylon 5 is just such a great show with fantastic characters, writing, and world-building.
Person 2: Agreed. It's one of my favorite sci-fi shows of all time and I'm always happy to revisit it.
Person 1: Same here. I think one of the things that makes Babylon 5 so special is its emphasis on politics and diplomacy. It's not just a show about space battles and aliens, but about the complex relationships between different species and their political maneuvering.
Person 2: Yes, that's definitely one of the show's strengths. And it's not just about big-picture politics, but also about personal relationships and the choices characters make.
Person 1: Exactly. I love how Babylon 5 explores themes of redemption, forgiveness, and sacrifice. Characters like G'Kar and Londo have such compelling arcs that are driven by their choices and actions.
Person 2: Yes, the character development in Babylon 5 is really top-notch. Even minor characters like Vir and Franklin get their moments to shine and grow over the course of the series.
Person 1: I couldn't agree more. And the way the show handles its themes is so nuanced and thought-provoking. For example, the idea of "the one" and how it's used by different characters in different ways.
Person 2: Yes, that's a really interesting theme to explore. And it's not just a one-dimensional concept, but something that's explored in different contexts and with different characters.
Person 1: And the show also does a great job of balancing humor and drama. There are so many funny moments in the show, but it never detracts from the serious themes and the high stakes.
Person 2: Absolutely. The humor is always organic and never feels forced. And the show isn't afraid to go dark when it needs to, like in "Intersections in Real Time" or the episode "Sleeping in Light."
Person 1: Yeah, those episodes are definitely tough to watch, but they're also some of the most powerful and memorable episodes of the series. And it's not just the writing that's great, but also the acting and the production values.
Person 2: Yes, the acting is fantastic across the board. From Bruce Boxleitner's performance as Sheridan to Peter Jurasik's portrayal of Londo, every actor brings their A-game. And the production design and special effects are really impressive for a TV show from the 90s.
Person 1: Definitely. Babylon 5 was really ahead of its time in terms of its visuals and special effects. And the fact that it was all done on a TV budget makes it even more impressive.
Person 2: Yeah, it's amazing what they were able to accomplish with the limited resources they had. It just goes to show how talented the people behind the show were.
Person 1: Agreed. It's no wonder that Babylon 5 has such a devoted fanbase, even all these years later. It's just such a well-crafted and timeless show.
Person 2: Absolutely. I'm glad we can still appreciate it and talk about it all these years later. It really is a show that stands the test of time.
Person 1: One thing I really appreciate about Babylon 5 is how it handles diversity and representation. It has a really diverse cast of characters from different species and backgrounds, and it doesn't shy away from exploring issues of prejudice and discrimination.
Person 2: Yes, that's a great point. The show was really ahead of its time in terms of its diverse cast and the way it tackled issues of race, gender, and sexuality. And it did so in a way that felt natural and integrated into the story.
Person 1: Definitely. It's great to see a show that's not afraid to tackle these issues head-on and address them in a thoughtful and nuanced way. And it's not just about representation, but also about exploring different cultures and ways of life.
Person 2: Yes, the show does a great job of world-building and creating distinct cultures for each of the species. And it's not just about their physical appearance, but also about their customs, beliefs, and values.
Person 1: Absolutely. It's one of the things that sets Babylon 5 apart from other sci-fi shows. The attention to detail and the thought that went into creating this universe is really impressive.
Person 2: And it's not just the aliens that are well-developed, but also the human characters. The show explores the different factions and political ideologies within EarthGov, as well as the different cultures and traditions on Earth.
Person 1: Yes, that's another great aspect of the show. It's not just about the conflicts between different species, but also about the internal struggles within humanity. And it's all tied together by the overarching plot of the Shadow War and the fate of the galaxy.
Person 2: Definitely. The show does a great job of balancing the episodic stories with the larger arc, so that every episode feels important and contributes to the overall narrative.
Person 1: And the show is also great at building up tension and suspense. The slow burn of the Shadow War and the mystery of the Vorlons and the Shadows kept me on the edge of my seat throughout the series.
Person 2: Yes, the show is really good at building up anticipation and delivering satisfying payoffs. Whether it's the resolution of a character arc or the climax of a season-long plotline, Babylon 5 always delivers.
Person 1: Agreed. It's just such a well-crafted and satisfying show, with so many memorable moments and characters. I'm really glad we got to talk about it today.
Person 2: Me too. It's always great to geek out about Babylon 5 with someone who appreciates it as much as I do!
Person 1: Yeah, it's always fun to discuss our favorite moments and characters from the show. And there are so many great moments to choose from!
Person 2: Definitely. I think one of the most memorable moments for me was the "goodbye" scene between G'Kar and Londo in the episode "Objects at Rest." It was such a poignant and emotional moment, and it really showed how far their characters had come.
Person 1: Yes, that was a really powerful scene. It was great to see these two former enemies come together and find common ground. And it was a great way to wrap up their character arcs.
Person 2: Another memorable moment for me was the speech that Sheridan gives in "Severed Dreams." It's such an iconic moment in the show, and it really encapsulates the themes of the series.
Person 1: Yes, that speech is definitely one of the highlights of the series. It's so well-written and well-delivered, and it really captures the sense of hope and defiance that the show is all about.
Person 2: And speaking of great speeches, what did you think of the "Ivanova is always right" speech from "Moments of Transition"?
Person 1: Oh man, that speech gives me chills every time I watch it. It's such a powerful moment for Ivanova, and it really shows her strength and determination as a leader.
Person 2: Yes, that speech is definitely a standout moment for Ivanova's character. And it's just one example of the great writing and character development in the show.
Person 1: Absolutely. It's a testament to the talent of the writers and actors that they were able to create such rich and complex characters with so much depth and nuance.
Person 2: And it's not just the main characters that are well-developed, but also the supporting characters like Marcus, Zack, and Lyta. They all have their own stories and struggles, and they all contribute to the larger narrative in meaningful ways.
Person 1: Definitely. Babylon 5 is just such a well-rounded and satisfying show in every way. It's no wonder that it's still beloved by fans all these years later.
Person 2: Agreed. It's a show that has stood the test of time, and it will always hold a special place in my heart as one of my favorite TV shows of all time.
Person 1: One of the most interesting ethical dilemmas presented in Babylon 5 is the treatment of the Narn by the Centauri. What do you think about that storyline?
Person 2: Yeah, it's definitely a difficult issue to grapple with. On the one hand, the Centauri were portrayed as the aggressors, and their treatment of the Narn was brutal and unjust. But on the other hand, the show also presented some nuance to the situation, with characters like Londo and Vir struggling with their own complicity in the conflict.
Person 1: Exactly. I think one of the strengths of the show is its willingness to explore complex ethical issues like this. It's not just about good guys versus bad guys, but about the shades of grey in between.
Person 2: Yeah, and it raises interesting questions about power and oppression. The Centauri had more advanced technology and military might than the Narn, which allowed them to dominate and subjugate the Narn people. But at the same time, there were also political and economic factors at play that contributed to the conflict.
Person 1: And it's not just about the actions of the Centauri government, but also about the actions of individual characters. Londo, for example, was initially portrayed as a somewhat sympathetic character, but as the series progressed, we saw how his choices and actions contributed to the suffering of the Narn people.
Person 2: Yes, and that raises interesting questions about personal responsibility and accountability. Can an individual be held responsible for the actions of their government or their society? And if so, to what extent?
Person 1: That's a really good point. And it's also interesting to consider the role of empathy and compassion in situations like this. Characters like G'Kar and Delenn showed compassion towards the Narn people and fought against their oppression, while others like Londo and Cartagia were more indifferent or even sadistic in their treatment of the Narn.
Person 2: Yeah, and that raises the question of whether empathy and compassion are innate traits, or whether they can be cultivated through education and exposure to different cultures and perspectives.
Person 1: Definitely. And it's also worth considering the role of forgiveness and reconciliation. The Narn and Centauri eventually came to a sort of reconciliation in the aftermath of the Shadow War, but it was a difficult and painful process that required a lot of sacrifice and forgiveness on both sides.
Person 2: Yes, and that raises the question of whether forgiveness is always possible or appropriate in situations of oppression and injustice. Can the victims of such oppression ever truly forgive their oppressors, or is that too much to ask?
Person 1: It's a tough question to answer. I think the show presents a hopeful message in the end, with characters like G'Kar and Londo finding a measure of redemption and reconciliation. But it's also clear that the scars of the conflict run deep and that healing takes time and effort.
Person 2: Yeah, that's a good point. Ultimately, I think the show's treatment of the Narn-Centauri conflict raises more questions than it answers, which is a testament to its complexity and nuance. It's a difficult issue to grapple with, but one that's worth exploring and discussing.
Person 1: Let's switch gears a bit and talk about the character of Natasha Alexander. What did you think about her role in the series?
Person 2: I thought Natasha Alexander was a really interesting character. She was a tough and competent security officer, but she also had a vulnerable side and a complicated past.
Person 1: Yeah, I agree. I think she added a lot of depth to the show and was a great foil to characters like Garibaldi and Zack.
Person 2: And I also appreciated the way the show handled her relationship with Garibaldi. It was clear that they had a history and a lot of unresolved tension, but the show never made it too melodramatic or over-the-top.
Person 1: That's a good point. I think the show did a good job of balancing the personal drama with the larger political and sci-fi elements. And it was refreshing to see a female character who was just as tough and competent as the male characters.
Person 2: Definitely. I think Natasha Alexander was a great example of a well-written and well-rounded female character. She wasn't just there to be eye candy or a love interest, but had her own story and agency.
Person 1: However, I did feel like the show could have done more with her character. She was introduced fairly late in the series, and didn't have as much screen time as some of the other characters.
Person 2: That's true. I think the show had a lot of characters to juggle, and sometimes that meant some characters got sidelined or didn't get as much development as they deserved.
Person 1: And I also thought that her storyline with Garibaldi could have been developed a bit more. They had a lot of history and tension between them, but it felt like it was resolved too quickly and neatly.
Person 2: I can see where you're coming from, but I also appreciated the way the show didn't drag out the drama unnecessarily. It was clear that they both had feelings for each other, but they also had to focus on their jobs and the larger conflicts at play.
Person 1: I can see that perspective as well. Overall, I think Natasha Alexander was a great addition to the show and added a lot of value to the series. It's a shame we didn't get to see more of her.
Person 2: Agreed. But at least the show was able to give her a satisfying arc and resolution in the end. And that's a testament to the show's strength as a whole.
Person 1: One thing that really stands out about Babylon 5 is the quality of the special effects. What did you think about the show's use of CGI and other visual effects?
Person 2: I thought the special effects in Babylon 5 were really impressive, especially for a show that aired in the 90s. The use of CGI to create the spaceships and other sci-fi elements was really innovative for its time.
Person 1: Yes, I was really blown away by the level of detail and realism in the effects. The ships looked so sleek and futuristic, and the space battles were really intense and exciting.
Person 2: And I also appreciated the way the show integrated the visual effects with the live-action footage. It never felt like the effects were taking over or overshadowing the characters or the story.
Person 1: Absolutely. The show had a great balance of practical effects and CGI, which helped to ground the sci-fi elements in a more tangible and realistic world.
Person 2: And it's also worth noting the way the show's use of visual effects evolved over the course of the series. The effects in the first season were a bit rough around the edges, but by the end of the series, they had really refined and perfected the look and feel of the show.
Person 1: Yes, I agree. And it's impressive how they were able to accomplish all of this on a TV budget. The fact that the show was able to create such a rich and immersive sci-fi universe with limited resources is a testament to the talent and creativity of the production team.
Person 2: Definitely. And it's one of the reasons why the show has aged so well. Even today, the visual effects still hold up and look impressive, which is a rarity for a show that's almost 30 years old.
Person 1: Agreed. And it's also worth noting the way the show's use of visual effects influenced other sci-fi shows that came after it. Babylon 5 really set the bar for what was possible in terms of sci-fi visuals on TV.
Person 2: Yes, it definitely had a big impact on the genre as a whole. And it's a great example of how innovative and groundbreaking sci-fi can be when it's done right.
Person 1: Another character I wanted to discuss is Zathras. What did you think of his character?
Person 2: Zathras was a really unique and memorable character. He was quirky and eccentric, but also had a lot of heart and sincerity.
Person 1: Yes, I thought he was a great addition to the show. He added some much-needed comic relief, but also had some important moments of character development.
Person 2: And I appreciated the way the show used him as a sort of plot device, with his knowledge of time and space being instrumental in the resolution of some of the show's major storylines.
Person 1: Definitely. It was a great way to integrate a seemingly minor character into the larger narrative. And it was also interesting to see the different versions of Zathras from different points in time.
Person 2: Yeah, that was a clever storytelling device that really added to the sci-fi elements of the show. And it was also a great showcase for actor Tim Choate, who played the character with so much charm and energy.
Person 1: I also thought that Zathras was a great example of the show's commitment to creating memorable and unique characters. Even characters that only appeared in a few episodes, like Zathras or Bester, were given distinct personalities and backstories.
Person 2: Yes, that's a good point. Babylon 5 was really great at creating a diverse and interesting cast of characters, with each one feeling like a fully-realized and distinct individual.
Person 1: And Zathras was just one example of that. He was a small but important part of the show's legacy, and he's still remembered fondly by fans today.
Person 2: Definitely. I think his character is a great example of the show's ability to balance humor and heart, and to create memorable and beloved characters that fans will cherish for years to come.
"""


#Convert the conversation to lines
lines = conversation.lstrip('\n').rstrip('\n').split('\n')
for i in range(len(lines)):
  if lines[i].startswith('Person 1: '):
    key = 'my_user'
    message = lines[i].replace('Person 1: ', '')
  elif lines[i].startswith('Person 2: '):
    key = 'other_user'
    message = lines[i].replace('Person 2: ', '')
  else:
    print(lines[i])
    raise 'invalid line'
    
  created_at = (now + timedelta(minutes=i)).isoformat()
  
  create_message(
   client=ddb,
   message_group_id=message_group_uuid,
   created_at=created_at
   message=message
   my_user_uuid=users[key]['uuid'],
   my_user_display_name=users[key]['display_name'],
   my_user_handle=users[key]['handle']
 )
```

- Change the permissions of the seed bash script file by running, in the terminal:
```
chmod u+x bin/ddb/seed
./bin/ddb/seed
```

- First, we need to load the RDS table, therefore run in the terminal:
```
./bin/db/create
./bin/db/schema-load
./bin/db/seed
```

### Write AWS SDK code for DynamoDB to query and scan put-item, for predefined endpoints
**Step 6 -  Confirming that data was seeded by creating a scan Bash Script**
-  In the ddb folder, create a new file named ``scan`` to scan/query our tables:
```
#! /usr/bin/env python3

import bot3

attrs = {
  'endpoint_url': 'http://localhost:8000'
}

ddb = boto3.resource('dynamodb',**attrs)
table_name = 'cruddur-messages'

table = ddb.Table(table_name)
response = table.scan()

items = response['Items']
for item in items:
  print(item)
```

- Change the permissions of the scan bash script file by running, in the terminal:
```
chmod u+x bin/ddb/scan
./bin/ddb/scan
```

**Step 7 - Creating a patterns folder in ddb**
-  In the ddb folder, create a new folder named ```patterns```.
-  In the ddb/patterns folder, create a new file named ```get-conversations```.
-  In the ddb/patterns folder, create a new file named ```list-conversations```.
-  In the ddb/patterns/get-conversations file, paste in :
```
#!/usr/bin/env python3

import boto3
import sys
import json
import datetime

attrs = {
  'endpoint_url': 'http://localhost:8000'
}

if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}

dynamodb = boto3.client('dynamodb',**attrs)
table_name = 'cruddur-messages'

message_group_uuid = "5ae290ed-55d1-47a0-bc6d-fe2bc2700399"

# define the query parameters
query_params = {
  'TableName': table_name,
  'ScanIndexForward': True,
  'Limit': 20,
  'KeyConditionExpression': 'pk = :pk AND begins_with(sk,:year)',
  #'KeyConditionExpression': 'pk = :pk AND sk BETWEEN :start_date AND :end_date',  
  'ExpressionAttributeValues': {
    ':year': {'S': '2023'},
    #':start_date': { "S": "2023-03-01T00:00:00.000000+00:00"},
    #':end_date': { "S": "2023-03-19T23:59:59.999999+00:00"},  
    ':pkey': {'S': f"MSG#{message_group_uuid}"}
  },
  'ReturnConsumedCapacity': 'TOTAL'
}

# query the table
response = dynamodb.query(**query_params)

# print the items returned by the query
print(json.dumps(response, sort_keys=True, indent=2))

# print the consumed capacity
print(json.dumps(response['ConsumedCapacity'], sort_keys=True, indent=2))

items = response['Items']
reversed_array = items[::-1]

for item in reversed_array:
  sender_handle = item['user_handle']['S']
  message       = item['message']['S']
  timestamp     = item['sk']['S']
  dt_object = datetime.datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%S.%f%z')
  formatted_datetime = dt_object.strftime('%Y-%m-%d %I:%M %p')
  print(f'{sender_handle: <16}{formatted_datetime: <22}{message[:40]}...')
```

- Change the permissions of the scan bash script file by running, in the terminal:
```
chmod u+x bin/ddb/patterns/get-conversations
./bin/ddb/patterns/get-conversations
```

- In the ddb/patterns/list-conversations file, paste in :
```
#!/usr/bin/env python3

import boto3
import sys
import json
import os

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..', '..'))
sys.path.append(parent_path)
from lib.db import db

attrs = {
  'endpoint_url': 'http://localhost:8000'
}

if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}

dynamodb = boto3.client('dynamodb',**attrs)
table_name = 'cruddur-messages'

def get_my_user_uuid():
  sql = """
    SELECT 
      users.uuid,
    FROM users
    WHERE
      users.handle=%(my_handle)s,
  """

uuid = db.query_value(sql,{
   'handle':  'andrewbrown',
 })
return uuid 
 
my_user_uuid = get_my_user_uuid()
print(f"my-uuid: {my_user_id}")

# define the query parameters
query_params = {
  'TableName': table_name,
  'KeyConditionExpression': 'pk = :pk',
  #'ScanIndexForward': False,
  'ExpressionAttributeValues': {
    ':pk': {'S': f"GRP#{brown_user_uuid}"}
  },
  'ReturnConsumedCapacity': 'TOTAL'
}

# query the table
response = dynamodb.query(**query_params)

# print the items returned by the query
print(json.dumps(response, sort_keys=True, indent=2))
```

- To get the value of 
"my_user_uuid = "1506fa16-d775-4808-9f46-456661029af2", in the terminal, make sure that we are in backend-flask folder and run , then in the cruddur prompt, run line 2:
```
./bin/db-connect
SELECT uuid, handle from users;
```
***(this value will always have to be updated whenever we seed the database because the uuid is ever-changing and the )***

- Then copy the uuid of andrew brown and paste into the line as above.
- Change the permissions of the scan bash script file by running, in the terminal:
```
chmod u+x bin/ddb/patterns/list-conversations
./bin/ddb/patterns/list-conversations
```

- Paste the following code in lib/db.py
```
# when we want to return a a single value
  def query_value(self,sql,params={}):
    self.print_sql('value',sql,params)

    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql,params)
        json = cur.fetchone()
        return json[0]

```

### Update our backend app to use the production DynamoDB
**Step 8 - jjkk**
- In gitpod.yml add in:
```
name: flask
command: |
  cd backend-flask
  pip install -r requirements.txt
```

- In the bin/ddb/seed file, add/replace the last line with:
```psql $NO_DB_CONNECTION_URL -c "drop database IF EXISTS cruddur;"```

- In the terminal, run ```pip install -r requirements.txt``` then run Docker compose up in the terminal.
- Open our front-end application in a new tab and try to sign in.
- Switch to the messages tab.
- Create a DynamoDB object by creating a ddb.py file in the backend-flask/lib folder.
```
import boto3
import sys
from datetime import datetime, timedelta, timezone
import uuid
import os

class Ddb:
  def client():
    endpoint_url = os.getenv("AWS_ENDPOINT_URL")
    if endpoint_url:
      attrs = { 'endpoint_url': endpoint_url }
    else:
      attrs = {}
    dynamodb = boto3.client('dynamodb',**attrs)
    return dynamodb

 def list_message_groups(client,my_user_uuid):
    table_name = 'cruddur-messages'
    query_params = {
      'TableName': table_name,
      'KeyConditionExpression': 'pk = :pk',
      'ScanIndexForward': False,
      'Limit': 20,
      'ExpressionAttributeValues': {
        ':pk': {'S': f"GRP#{my_user_uuid}"}
      }
    }
    print('query-params')
    print(query_params)
    print('client')
    print(client)

    # query the table
    response = client.query(**query_params)
    items = response['Items']
    
    results = []
    for item in items:
      last_sent_at = item['sk']['S']
      results.append({
        'uuid': item['message_group_uuid']['S'],
        'display_name': item['user_display_name']['S'],
        'handle': item['user_handle']['S'],
        'message': item['message']['S'],
        'created_at': last_sent_at
      })
    return results
```

- In the list-conversation file, paste in  ```'ScanIndexForward': False,```:
- Change into the ```backend-flask directory``` and in the terminal paste in line 2:
```
aws cognito-idp list-users --user-pool-id-(paste in user id here)
```

- We need to set the cognito user pool environment, so we will first retrieve the cognito user pool id for the cruddur-user-pool and then set it as an environment variable by entering in the terminal:
```
export AWS_COGNITO_USER_POOL_ID="valuevaluevalue"
gp env AWS_COGNITO_USER_POOL_ID="valuevaluevalue"
env | grep AWS_COGNITO
```

- We will then update it in the backend by editing the Docker-compose file(to hard code it into the backend file):
```
AWS_COGNITO_USER_POOL_ID: "${AWS_COGNITO_USER_POOL_ID}"
```

- In the bin directory, create a new folder called cognito that will contain a file named list-users that will list users.
```
#!/usr/bin/env python3

import boto3
import os
import json

userpool_id = os.getenv("AWS_COGNITO_USER_POOL_ID")
client = boto3.client('cognito-idp')
params = {
  'UserPoolId': userpool_id,
  'AttributesToGet': [
      'preferred_username',
      'sub'
  ]
}
response = client.list_users(**params)
users = response['Users']

print(json.dumps(users, sort_keys=True, indent=2, default=str))

dict_users = {}
for user in users:
  attrs = user['Attributes']
  sub    = next((a for a in attrs if a["Name"] == 'sub'), None)
  handle = next((a for a in attrs if a["Name"] == 'preferred_username'), None)
  dict_users[handle['Value']] = sub['Value']

print(json.dumps(dict_users, sort_keys=True, indent=2, default=str))

```

- Change the permissions of the list-users file by running in the terminal:
```
chmod u+x bin/cognito/list-users
.bin/cognito/list-users
```

**Step 9 - jjkk**
- We now need to create a script to update the user ids into our database.
- In the db directory, create a new bash update-cognito-user id script 
```
#!/usr/bin/env python3

import boto3
import os
import sys

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..'))
sys.path.append(parent_path)
from lib.db import db

def update_users_with_cognito_user_id(handle,sub):
  sql = """
    UPDATE public.users
    SET cognito_user_id = %(sub)s
    WHERE
      users.handle = %(handle)s;
  """
  db.query_commit(sql,{
    'handle' : handle,
    'sub' : sub
  })

def get_cognito_user_ids():
  userpool_id = os.getenv("AWS_COGNITO_USER_POOL_ID")
  client = boto3.client('cognito-idp')
  params = {
    'UserPoolId': userpool_id,
    'AttributesToGet': [
        'preferred_username',
        'sub'
    ]
  }
  response = client.list_users(**params)
  users = response['Users']
  dict_users = {}
  for user in users:
    attrs = user['Attributes']
    sub    = next((a for a in attrs if a["Name"] == 'sub'), None)
    handle = next((a for a in attrs if a["Name"] == 'preferred_username'), None)
    dict_users[handle['Value']] = sub['Value']
  return dict_users


users = get_cognito_user_ids()

for handle, sub in users.items():
  print('----',handle,sub)
  update_users_with_cognito_user_id(
    handle=handle,
    sub=sub
  )
```

- In the db/setup file, we will add a new line
``` source "$bin_path/db/update_cognito_user_ids" ```

- Before seeding our data , we need to make sure that Docker-compose is up and running then we will run
```
chmod u+x bin/db/update_cognito_user_ids
./bin/db/setup
```

- Update a line into d.py file
-  


### Security best practises for DynamoDB
**Types of Access to DynamoDB**
- Using Internet Gateway.
- Using VPC/Gateway Endpoints
- DynamoDB Accelerator(DAX)
- Cross Account

**Security best Practises - AWS**
Amazon Dynamodb is part of an  account NOT a virtual Network
- Use VPC endpoints: Use Amazon VPC to create a private network from our application or Lambda to a DynamoDB . This prevents unauthorized access to the instance from the public internet.
- Data Security & Compliance: Compliance standard should be followed for the business requirements.
- Amazon DynamoDB should only be in the AWS region that we are legally allowed to hold user data in.
- Amazon organizations SCP - to manage DynamoDB Table deletion, DynbamoDB creation, region lock.
- AWS CloudTrail is enabled & monitored to trigger appropriate alerts on malicious DynamoDB behaviour by an identity in AWS.
- AWS Config rules is enabled in the account and region of DynamoDB.

**Security best Practises - Application**
AWS recommends using Client side encryption when storing sensitive information. But dynamoDB should not be used to store sensitive information, RDS databases should be used instead to store sensitive information for long periods.
- DynamoDB to use appropriate Authentication - Use IAM Roles/ AWS Cognito Identity Pool (Avoid IAM Users/Groups).
- DynamoDB User Lifecycle Management - Create, Modify, Delete Users.
- AWS IAM roles instead of individual users to access and manage DynamoDB.
- DAX Service9IAM) Role to have Read Only Access to DynamoDB.
- Not have DynamoDB be accessed from the internet(use VPC endpoints instead).
- Site-to-Site VPN or Direct Connect for Onpremise and DynamoDB Access.
- Client side encryption is recommended by Amazon for DynamoDB.

# Errors I have encountered so far and how i resolved them #
## 1. While running ./bin/cognito/list-users ## 
```Traceback (most recent call last):
  File "/workspace/aws-bootcamp-cruddur-2023/backend-flask/./bin/cognito/list-users", line 26, in <module>
    dict_users[handle['Value']] = sub['Value']
               ~~~~~~^^^^^^^^^
TypeError: 'NoneType' object is not subscriptable
```

2. While running ./bin/db/update_cognito_user_ids 
```Traceback (most recent call last):
  File "/workspace/aws-bootcamp-cruddur-2023/backend-flask/./bin/cognito/list-users", line 26, in <module>
    dict_users[handle['Value']] = sub['Value']
               ~~~~~~^^^^^^^^^
TypeError: 'NoneType' object is not subscriptable
```

SOLUTION
3. While trying to connect to my postgres database, the records/users had been added twice from my cognito user pool id and when i tried dropping the Cruudur postgres datase database I woul encounter this error
```
== db-drop
ERROR:  database "cruddur" is being accessed by other users
DETAIL:  There are 4 other sessions using the database.
```

From the discord channel, a tip dropped there suggested using this command
```
REVOKE CONNECT ON DATABASE cruddur FROM public;
ALTER DATABASE cruddur allow_connections = off;
SELECT pg_terminate_backend(pg_stat_activity.pid
) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'cruddur'; DROP DATABASE cruddur;
```
I connected to the database by:
```./bin/db/connect```
then once in the cruddur database, run the command above.
When i tried running ```./bin/db/drop``` once again it worked.
Thus i ran, ```./bin/db/setup```, then ./bin/cognito/list-users

## 2. Getting -ve time values on our messages ##
While the messages would show in our application, they would show negative times thus meaning when we posted new messages they wouldn't be displayed on our timeline.
A helpful bootcamper suggested editing this line in ```backend-flask/bin/ddb/seed```
```
change this line 
  created_at = (now + timedelta(minutes=i)).isoformat()
to
  created_at = (now + timedelta(hours=-3) + timedelta(minutes=i)).isoformat()
```
- Then drop the database and recreate it then seed it using these steps:
```
./bin/ddb/drop cruddur-messages 
./bin/ddb/load-schema 
./bin/ddb/seed
```

## Next Steps - Additional Homework Challenges



**RESOURCES**
1. [NoSQL DynamoDB Workbench](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/workbench.html)
2. [AWS SDK Boto3 Python DynamoDB Documentation]([https://boto3.amazonaws.com/v1/documentation/api/latest/guide/dynamodb.html](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dynamodb/client/create_table.html))
3. PartQL
4. No-SQL Workbench
