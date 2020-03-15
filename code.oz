local
   % See project statement for API details.
   [Project] = {Link ['Project2018.ozf']}
   Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %Verrifie si N est de un recod note ou chord
   fun{IsExtanded N}
      if N == silence then false
      else case N
	   of H|T then {IsExtanded H}
	   else
	      local Name in
		 Name = {Label N}
		 Name == note orelse Name == silence
	      end
	   end
      end
   end

   %Retourne la Note en record note
   fun {NoteToExtended Note}
      case Note
      of Name#Octave then
	 note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
      [] Atom then
	 case {AtomToString Atom}
	 of [_] then
	    note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
	 [] [N O] then
	    note(name:{StringToAtom [N]}
		 octave:{StringToInt [O]}
		 sharp:false
		 duration:1.0
		 instrument: none)
	 else
	    silence(duration:1.0)
	 end
      end
   end

    %Retourne la Chord en record chord
   fun {ChordToExtended Chord}
      case Chord
      of nil then nil
      [] H|T then {NoteToExtended H}|{ChordToExtended T}
      end
   end

   %Ajoute l'appel de Ftc pour K à la fin de la liste P .utilise pour PartitionToTimedList
   fun{Ajouter P Fct K}
      case P
      of nil then {Fct K}
      [] H|T then H|{Ajouter T Fct K}
      end
   end

   %Ajoute l'appel de Ftc pour K à la fin de la liste P (utilise pour Mix)
   fun{AjouterMix P Fct P2T K}
      case P
      of nil then {Fct P2T K}
      [] H|T then H|{AjouterMix T Fct P2T K}
      end
   end

   %Record contenant les information  des notes d'une octave en fonction d'un nombre
   NumberToNote = numbertonotes(0:note(name:b sharp:false)
				1: note(name:c sharp:false)
				2: note(name:c sharp:true)
				3: note(name:d sharp:false)
				4: note(name:d sharp:true)
				5: note(name:e sharp:false)
				6: note(name:f sharp:false)
				7: note(name:f sharp:true)
				8: note(name:g sharp:false)
				9: note(name:g sharp:true)
				10:note(name:a sharp:false)
				11:note(name:a sharp:true)
				12:note(name:b sharp:false))
   
   %Fonction retourant un nombre en fonction de ses informations. nom et sharpde S semitones
   fun{NoteToNumb N}
      local
	 S = if N.sharp then 1 else 0 end
	 Name = N.name
      in
	 if Name == c then 1+S
	 elseif Name == d then 3+S
	 elseif Name == e then 5
	 elseif Name == f then 6+S
	 elseif Name == g then 8+S
	 elseif Name == a then 10+S
	 else 12
	 end
      end
   end

   %Fonction renourant la partition P transposee de S semitones
   %Transnote retourne une note ou un chord transpose de S semitones
   fun{Transpose P S}
      local
	 NP = {PartitionToTimedList P}
	 fun{TransNote N S}
	    case N
	    of nil then nil
	    [] H|T then {TransNote H S}|{TransNote T S}
	    else
	       local NN NO NNumb Pas
	       in
		  if S >= 0 then
		     Pas = {NoteToNumb N}+S
		     NO = N.octave+( (Pas-1) div 12)
		     NNumb = (Pas mod 12 )
		     NN =  NumberToNote.NNumb
		     note(name:NN.name sharp:NN.sharp octave:NO duration:N.duration instrument:N.instrument)
		  else
		     Pas = {NoteToNumb N}+S
		     NO = N.octave+( (Pas-12) div 12)
		     NNumb = ((Pas - 12) mod  12)+12
		     NN =  NumberToNote.NNumb
		     note(name:NN.name sharp:NN.sharp octave:NO duration:N.duration instrument:N.instrument)
		  end
	       end
	    end
	 end
      in
	 case NP
	 of nil then nil
	 [] H|T then
	    {TransNote H S}|{Transpose T S}
	 end
      end
   end

   %retourne la note N en record note ou chord
   fun{ExtendN N}
      case N
      of H|T then {ChordToExtended N}
      else {NoteToExtended N}
      end
   end
   
   %Retourne une liste composee de A fois la note N
   fun{Drone N A P}
      if A == 0 then P
      else {Drone N A-1 (N|P)}
      end
   end

   %Retoune la Partition P donc la duree des notes a ete multiplie par F
   fun{Stretch P F}
      local
	 fun{StretchNote N F}
	    case N
	    of H|T then
	       local
		  fun {StretchChord C F}
		     case C
		     of nil then nil
		     [] H|T then {StretchNote H F}|{StretchChord T F}
		     end
		  end
	       in
		  {StretchChord N F}
	       end
	    elseif {Label N} == note then
	       note(name:N.name octave:N.octave sharp:N.sharp duration:(N.duration*F) instrument:N.instrument)
	    else silence(duration:(N.duration*F))
	    end
	 end
      in
	 case P
	 of nil then nil
	 [] H|T then {StretchNote H F}|{Stretch T F}
	 end
      end
   end

   %Retoune la partition Part pour qu elle ait une duree S
   fun{Duration Part S}
      local
	 fun{Sum Part Acc}
	    case Part
	    of nil then Acc
	    [] H|T then
	       case H
	       of K|J then
		  {Sum T Acc+K.duration}
	       else
		  {Sum T Acc+H.duration}
	       end
	    end
	 end
	 Duree
	 Facteur
      in
	 Duree = {Sum Part 0.0}
	 Facteur = S/Duree
	 {Stretch Part Facteur}
      end
   end

   %Renvoie le normbre de semitons separant la note N de la note a4
   fun{Hauteur N}
      case N
      of note(name:Name octave:O sharp:S duration:D instrument:I) then
	 12*(O-4)+{NoteToNumb N}-10
      end
   end
   
   %Additionne les listes L1 et L2. Si une liste est plus petite que l autre, place la fin de la plus longue .
   fun{Add L1 L2}
      case L1
      of nil then
	 case L2
	 of nil then
	    nil
	 [] H|T then
	    H|{Add nil T}
	 end
      []H|T then
	 case L2
	 of nil then
	    H|{Add T nil}
	 []K|J then
	    H+K|{Add T J}
	 end
      end
   end

   %Fonction qui renvoie une liste d echantillons en fonction de la note N
   fun {NoteToEchantillon N}
      case N
      of H|T then
	 local
	    fun{ChordToEchantillon C}
	       case C
	       of H|nil then {NoteToEchantillon H}
	       [] H|T then
		  {Add {NoteToEchantillon H} {ChordToEchantillon T}}
	       end
	    end
	 in
	    {ChordToEchantillon N}
	 end
      [] note(name:Name octave:O sharp:S duration:D instrument:I) then
	 local
	    I = {FloatToInt D*44100.0}
	    H = {IntToFloat {Hauteur N}}
	    F = {Pow 2.0 (H/12.0)} *440.0
	 in
	    {CreateEchantillon I F nil}
	 end
      [] silence(duration:D) then
	 local
	    I = {FloatToInt D*44100.0}
	 in
	    {CreateEchantillon I 0.0 nil}
	 end
      end
   end

   %Cree une liste de I echantillon en fonction de la frequence
   fun{CreateEchantillon I Freq Echantillon}
      if I == 0 then
	 Echantillon
      elseif Freq == 0.0 then
	 {CreateEchantillon I-1 Freq 0.0|Echantillon}
      else
	 local
	    E = 0.5*{Sin (2.0*3.14159265359*Freq*({IntToFloat I}/44100.0))}
	 in
	    {CreateEchantillon I-1 Freq E|Echantillon}
	 end
      end
   end

   %Renvoie la liste H suivi de la liste  T
   fun{Assembler H T}
      case H
      of nil then T
      [] K|J then K|{Assembler J T}
      end
   end

   %Retourne la partition Part en une suite d echantillon
   fun{Echantillon Part}
      case Part
      of nil then nil
      [] H|T then {Assembler {NoteToEchantillon H} {Echantillon T}}
      end
   end

   %Repete N fois la musique Music
   fun{Repeat N Music}
      if N == 0 then nil
      else {Assembler Music {Repeat N-1 Music}}
      end
   end

   %Inverse les elements de X 
   fun {DoReverse X Y}
      case X of nil then Y
      [] X|Xr then {DoReverse Xr X|Y}
      end
   end
   
   fun {Reverse Music}
      {DoReverse Music nil}
   end

   %Multiplie chaque element de la liste F par le facteur F
   fun{Mult L F}
      case L
      of nil then nil
      [] H|T then
	 F*H|{Mult T F}
      end
   end

   %Retourne la somme des echantillons des musiques de L multipliees par leur intensite F 
   fun{Merge L Ftc}
      case L
      of nil then nil
      [] H|T then
	 case H
	 of F#Music
	 then
	    local
	       Echantillon = {Mix Ftc Music}
	       Intensite = {Mult Echantillon F}
	    in
	       {Add Intensite {Merge T Ftc}}
	    end
	 end
      end
   end

   %Boucle la liste L jusqu a avoir une liste de longueur D. Lin permet de garder la liste intacte pour repeter la fonction
   fun{Loop D L Lin}
      if D == 0 then nil
      else
	 case L
	 of nil then
	    {Loop D Lin Lin}
	 [] H|T then
	    H|{Loop (D-1) T Lin}
	 end
      end
   end

   %Contraint des echantillons a respecter la valeur plancher Low et plafond Hi
   fun{Clip Low Hi Music}
      case Music
      of nil then nil
      [] H|T then
	 if H > Hi then
	    Hi|{Clip Low Hi T}
	 elseif H < Low then
	    Low|{Clip Low Hi T}
	 else
	    H|{Clip Low Hi T}
	 end
      end
   end

   %Introduit un echo dans la musique avec un silence de Silence secondes
   fun{Echo Silence Factor Music}
      local
	 Music2 = {Mult Music Factor}
	 Ec = {Assembler Silence Music2}
      in
	 {Add Music Ec}
      end
   end

   %Change l intensite au debut de la musique pendant D secondes
   fun{Fade D M}
      local
	 Nbr = D * 44100.0
	 fun{CreateE Nbr I}
	    if I == Nbr then nil
	    else
	       I/Nbr|{CreateE Nbr I+1.0}
	    end
	 end
	 fun{Fade2 E M}
	    case E
	    of nil then M
	    [] H|T then
	       case M
	       of K|J then
		  H*K|{Fade2 T J}
	       end
	    end
	 end
	 E
      in
	 E = {CreateE Nbr 0.0}
	 {Fade2 E M}
      end
   end

   %Recupere une portion de la musique entre le temps S et F
   fun{Cut S F Music}
      local
	 fun{Retirer Start Music}
	    case Music
	    of H|T then
	       if Start =< 0.0 then Music
	       else
		  {Retirer Start-1.0 T}
	       end
	    end
	 end

	 fun{Prendre Finish Music}
	    if Finish =< 0.0 then nil
	    else case Music
		 of nil then 0.0|{Prendre Finish-1.0 nil}
		 [] H|T then H|{Prendre Finish-1.0 T}
		 end
	    end
	 end
	 Start = S*44100.0
	 Finish= (F-S)*44100.0
      in
	 {Prendre Finish {Retirer Start Music}}
      end
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {PartitionToTimedList Partition}
      case Partition
      of nil then nil
      [] H|T then
	 if {IsExtanded H} then
	    H|{PartitionToTimedList T}
	 else
	    case H
	    of K|J then {ChordToExtended H}|{PartitionToTimedList T}
	    [] Name#Octave then {NoteToExtended H}|{PartitionToTimedList T}
	    else
	       local
		  Transformation = {Label H}
	       in
		  if Transformation == transpose
		     orelse Transformation == drone
		     orelse Transformation == duration
		     orelse Transformation == stretch then
		     case H
		     of transpose(semitones:S Part)then
			local
			   P
			   NP
			in
			   P = {PartitionToTimedList Part}
			   NP = {Transpose P S}
			   {Ajouter NP PartitionToTimedList T}
			end
		     [] drone(note:N amount:A) then
			local
			   NP
			in
			   NP = {Drone {ExtendN N} A nil}
			   {Ajouter NP PartitionToTimedList T}
			end

		     elseif Transformation == stretch orelse Transformation == duration then
			case H
			of stretch(factor:F Part) then
			   local
			      P = {PartitionToTimedList Part}
			      NP = {Stretch P F}
			   in
			      {Ajouter NP PartitionToTimedList T}
			   end
			[] duration(seconds:S Part) then
			   local
			      N = {PartitionToTimedList Part}
			      NP
			   in
			      NP = {Duration N S}
			      {Ajouter NP PartitionToTimedList T}
			   end
			end
		     end
		  else
		     {NoteToExtended H}|{PartitionToTimedList T}
		  end	       
	       end
	    end
	 end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{Mix P2T Music}
      case Music
      of nil then nil
      [] H|T then
	 case H
	 of samples(Sample)then
	    {AjouterMix Sample Mix P2T T}
	 [] partition(Part)then
	    local
	       NP = {P2T Part}
	    in
	       {AjouterMix {Echantillon NP} Mix P2T T}
	    end
	 []repeat(amount:N Music) then
	    local
	       Echantillon = {Mix P2T Music}
	    in
	       {AjouterMix {Repeat N Echantillon} Mix P2T T}
	    end
	 []reverse(Music) then
	    local
	       Echantillon = {Mix P2T Music}
	    in
	       {AjouterMix {Reverse Echantillon} Mix P2T T}
	    end
	 []wave(N) then
	    {AjouterMix {Project.readFile N} Mix P2T T}
	 []merge(Musiques) then
	    {AjouterMix {Merge Musiques P2T} Mix P2T T}
	 []loop(seconds:D Musique) then
	    local
	       Echantillon = {Mix P2T Musique}
	       ND = D*44100.0
	       NND = {FloatToInt ND}
	    in
	       {AjouterMix {Loop NND Echantillon Echantillon} Mix P2T T}
	    end
	 []clip(low:L high:H Musique) then
	    local
	       Echantillon = {Mix P2T Musique}
	    in
	       {AjouterMix {Clip L H Echantillon} Mix P2T T}
	    end
	 []echo(delay:D decay:F Musique) then
	    local
	       Echantillon = {Mix P2T Musique}
	       Silence = {Mix P2T [partition([silence(duration:D)])]}
	    in
	       {AjouterMix {Echo Silence F Echantillon} Mix P2T T}
	    end
	 []fade(start:S out:O Musique) then
	    local
	       Echantillon = {Mix P2T Musique}
	       Ne = {Fade S Echantillon}
	       NeReverse ={Reverse Ne}
	       Ne2 ={Fade O NeReverse}	       
	    in
	       {AjouterMix {Reverse Ne2} Mix P2T T}
	    end
	 []cut(start:S finish:F Musique) then
	    local
	       Echantillon = {Mix P2T Musique}
	    in
	       {AjouterMix {Cut S F Echantillon} Mix P2T T}
	    end
	    
	 end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   Music = {Project.load 'example.dj.oz'}
   Start

   % Uncomment next line to insert your tests.
   % \insert 'tests.oz'
   % !!! Remove this before submitting.
in
   Start = {Time}

   % Uncomment next line to run your tests.
   % {Test Mix PartitionToTimedList}

   % Add variables to this list to avoid "local variable used only once"
   % warnings.
   {ForAll [NoteToExtended Music] Wait}
   
   % Calls your code, prints the result and outputs the result to `out.wav`.
   % You don't need to modify this.
   {Browse {Project.run Mix PartitionToTimedList Music 'out.wav'}}
   
   % Shows the total time to run your code.
   {Browse {IntToFloat {Time}-Start} / 1000.0}
end