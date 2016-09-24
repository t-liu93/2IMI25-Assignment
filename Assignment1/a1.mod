using CP;
//using Opl;

tuple Character {
  key string name;
  string type;
}
tuple Scene {
  key string name;
  {string} characterSet;
}



{string} CharacterTypes = ...;

{string} LeadingCharacters = ...;

int maxNrOfCharacters = ...;

{Scene} Scenes = ...;
{Character} Characters with type in CharacterTypes = ...;

tuple Actor {
  key int id;
  string type;
  {string} assignedCharacters;
}
{Actor} Actors;

dvar int assignment[Scenes][Characters];
//dvar int assignment[Characters][Actors] in 0..1;

dvar int NrOfActorsNeeded;
execute {


  var cardc = Opl.card(Characters);
  writeln("Number of Characters:", cardc);
for( var i = 0; i < cardc; i++){
	var c=Characters[i];
	writeln(c.name,c.type);
//	Actors[i]=<i,c.type,{c.name}>;
}

}


minimize
  NrOfActorsNeeded;



subject to {
  forall ( s in Scenes, c in Characters )
    assignment[s][c] == ( c.name in s.characterSet );

}

//fill in from your decision variables.
int nrOfActorsOfType[ct in CharacterTypes];

//fill in from your decision variables.
{Character} CharactersPlayedByActor[i in 0 .. NrOfActorsNeeded - 1];

execute {
  writeln("Actors needed: ", NrOfActorsNeeded);
  for ( var ct in CharacterTypes) {
    writeln(ct, " needed: ", nrOfActorsOfType[ct]);
  }
  for ( var i = 0; i < NrOfActorsNeeded; i++) {
    writeln("Actor ", i, " plays ", CharactersPlayedByActor[i]);
  }
}