/*********************************************
 * OPL 12.6.3.0 Model
 * Author 1: Tianyu Liu (0937147), e-mail: t.liu.1@student.tue.nl
 * Author 2: Li Wang (0977456), e-mail: l.wang.3@student.tue.nl
 * Creation Date: Sep 24, 2016 at 4:12:35 PM
 * Last Modified Date: Oct 7, 2016
*********************************************/
using CP;

/* New tuple type represent characters. Use name as key. */
tuple Character {
  key string name;
  string type;
}

/* New tuple tuple represent scenes. */
tuple Scene {
  string name;
  {string} characterSet;
}

{string} CharacterTypes = ...;//Character types as string array, read from dat.
{string} LeadingCharacters = ...;//Leading characters as string array, read from dat.
int maxNrOfCharacters = ...;//A maximum number of character an actor can play, raed from dat.
{Scene} Scenes = ...;//Scenes as scene type array, read from dat.
{Character} Characters with type in CharacterTypes = ...;//Characters with type, read from dat.

int characterNumbers;//The total number of characters provided by dat.
int sceneNumbers;//The total number of scenes provided by dat.
int maxNumberOfCharacterOneScene = 0;//Used to set a lower bound

/* 
* Some calculations about the variables
* And runtime configurations
*/
execute {

  characterNumbers = Opl.card(Characters);//Calculate total character number from dat.
  writeln("Number of Characters:", characterNumbers);
  
  sceneNumbers = Opl.card(Scenes);//Calculate total scene number from dat.
  writeln("Number of Scenes:", sceneNumbers);
  
  for (var s in Scenes) {
    if (Opl.card(s.characterSet) > maxNumberOfCharacterOneScene) 
    	maxNumberOfCharacterOneScene = Opl.card(s.characterSet);
  }//Calculate max number of characters in a scene
  
  /*
  * Runtime configuration given in the assignment requirements
  */
  cp.param.Workers = 1;
  cp.param.TimeLimit = 5;
}

range characterRange = 0 .. characterNumbers - 1;//Range of character numbers

/* 
* Assignment represents the actors are assigned to a character.
* The value of assignment may represent the number of actors, start from 0
*/
dvar int assignment[ct in Characters] in characterRange;

dexpr int NrOfActorsNeeded = max ( c in Characters ) assignment[c] + 1;//The number of actors needed

minimize
  NrOfActorsNeeded;//Minimize the number of actors

subject to {  
/* Below are the constraints needed */

/*
* The decision variable assignment should be at least 0, and at most characterNumbers
*/
  forall ( c in Characters )
    assignment[c] >= 0 && assignment[c] < characterNumbers;
    
/*
* Constraint 1:
* Once an actor plays a certain character in a scene for example, 
* he or she needs to play that character in the whole play. 
*
* The decision variable assignment make sure this constraint holds.
*/

/*
* Constraint 2:
* Another constraint is that you cannot have two actors together play a character 
* as that will confuse the audience. 
*
* Decision variable make sure this constraint holds. 
*/


/*
* Solve constraint 3
* An actor obviously also cannot play more than one character in the same scene. 
* Implementation: In one scene, all actors with different characters are different. 
*/
  forall ( s in Scenes )
    allDifferent ( all ( c1 in s.characterSet, c2 in Characters : c1 == c2.name ) assignment[c2] );
    
/*
* Solve Constraint 4 v1.0
* There are furthermore a couple of leading characters and the actors assigned to those characters 
* cannot play any other character as that would again confuse the audience.
*/
  forall ( c1 in Characters, c2 in LeadingCharacters, c3 in Characters : c3.name == c2 && c1.name != c2 )
    assignment[c1] != assignment[c3];

/*
* Solve constraint 5
* There are also parts for males that can only be played by men, 
* parts for females that can only be played by women, etc. 
*/
  forall ( c1, c2 in Characters : c1.type != c2.type )
    assignment[c1] != assignment[c2];

/*
* Solve Constrtaint 6 v1.0
* Another constraint is that to allow people to change costume, 
* an actor cannot play one character in one scene and another in the scene that is directly next, 
* i.e., at least one scene needs to be in between any actor playing two different characters.
*/
  forall ( s1, s2 in Scenes : ord ( Scenes, s2 ) == ord ( Scenes, s1 ) + 1 )
    allDifferent ( all ( c in s1.characterSet union s2.characterSet ) assignment[< c >] );
    
/*
* Solve Constraint 7 v1.0
* A final constraint is that no actor can be assigned to more than a given maximal number of characters, 
* this as assigning too many characters to an actor will again confuse the audience.
* Implementation: Iterate all assignments over all characters in the range, 
* For different characters, the same number (i.e. the same actor) shows should be less or equal than max number.
*/
  forall ( c in characterRange )
    count ( all ( c2 in Characters ) assignment[c2], c ) <= maxNrOfCharacters;

/*
* Set constraints about NrOfActorsNeeded
* Use some bounds to increase efficiency 
*/
  NrOfActorsNeeded >= maxNumberOfCharacterOneScene;
  NrOfActorsNeeded <= characterNumbers;
}


//fill in from your decision variables.
int nrOfActorsOfType[ct in CharacterTypes];
//a temp variable helps to fill nrOfActorsOfType
{int} nrOfActorsOfTypeTemp[ct in CharacterTypes];

//fill in from your decision variables.
{Character} CharactersPlayedByActor[i in 0 .. NrOfActorsNeeded - 1];
execute {
  for ( var c in Characters) {
    CharactersPlayedByActor[assignment[c]].add(c);
  }//Fill in variable using decision variable
  for ( var cpa in CharactersPlayedByActor) {
    nrOfActorsOfTypeTemp[Opl.first(CharactersPlayedByActor[cpa]).type].add(cpa);
  }
  for ( var ct in CharacterTypes) {
    nrOfActorsOfType[ct] = Opl.card(nrOfActorsOfTypeTemp[ct]);
  }

  writeln("Actors needed: ", NrOfActorsNeeded);
  for ( var ct in CharacterTypes) {
    writeln(ct, " needed: ", nrOfActorsOfType[ct]);
  }
  for ( var i = 0; i < NrOfActorsNeeded; i++) {
    writeln("Actor ", i, " plays ", CharactersPlayedByActor[i]);
  }
}