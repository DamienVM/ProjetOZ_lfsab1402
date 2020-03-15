local
   % See project statement for API details.
   [Project] = {Link ['Project2018.ozf']}
   Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

   fun {ChordToExtended Chord}
      case Chord
      of nil then nil
      [] H|T then {NoteToExtended H}|{ChordToExtended T}
      end
   end

   fun{Ajouter P K}
      case P
      of nil then {PartitionToTimedList K}
      [] H|T then H|{Ajouter T K}
      end
   end

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

   fun{ExtendN N}
      case N
      of H|T then {ChordToExtended N}
      else {NoteToExtended N}
      end
   end

   fun{Drone N A P}
      if A == 0 then P
      else {Drone N A-1 (N|P)}
      end
   end


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

   fun{Hauteur N}
      case N
      of note(name:Name octave:O sharp:S duration:D instrument:I) then	 
	 12*(O-4)+{NoteToNumb N}-10
      end
   end

   fun{Add L1 L2}
      case L1
      of nil then nil
      [] H|T then H+L2.1|{Add T L2.2}
      end
   end

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

   fun{Assembler H T}
      case H
      of nil then T
      [] K|J then K|{Assembler J T}
      end
   end

   fun{Echantillon Part}
      case Part
      of nil then nil
      [] H|T then {Assembler {NoteToEchantillon H} {Echantillon T}}
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
			   {Ajouter NP T}
			end
		     [] drone(note:N amount:A) then
			local
			   NP
			in
			   NP = {Drone {ExtendN N} A nil}
			   {Ajouter NP T}
			end

		     elseif Transformation == stretch orelse Transformation == duration then
			case H
			of stretch(factor:F Part) then
			   local
			      P = {PartitionToTimedList Part}
			      NP = {Stretch P F}
			   in
			      {Ajouter NP T}
			   end
		     [] duration(seconds:S Part) then
			   local
			      N = {PartitionToTimedList Part}
			      NP
			   in
			      NP = {Duration N S}
			      {Ajouter NP T}
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

   fun {Mix P2T Music}
      case Music
      of nil then nil
      [] H|T then
	 local
	    fun {Ajouter P K}
	       case P
	       of nil then {Mix P2T K}
	       [] H|T then H|{Ajouter T K}
	       end
	    end
	 in
	    case H
	    of samples(Sample)then
	       {Ajouter Sample T}
	    [] partition(Part)then
	       local
		  NP = {P2T Part}
	       in
		  {Echantillon NP}
	       end
	    end
	 end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   Music = {Project.load 'joy.dj.oz'}
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