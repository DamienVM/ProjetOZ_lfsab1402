local
   [Project] = {Link ['Project2018.ozf']}
   
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

   fun{Ajouter P Fct K}
      case P
      of nil then {Fct K}
      [] H|T then H|{Ajouter T Fct K}
      end
   end

   fun{AjouterMix P Fct P2T K}
      case P
      of nil then {Fct P2T K}
      [] H|T then H|{AjouterMix T Fct P2T K}
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

   fun{Repeat N Music}
      if N == 0 then nil
      else {Assembler Music {Repeat N-1 Music}}
      end
   end

   fun {DoReverse X Y}
      case X of nil then Y
      [] X|Xr then {DoReverse Xr X|Y}
      end
   end
   
   fun {Reverse Music}
      {DoReverse Music nil}
   end

   fun{Mult L F}
      case L
      of nil then nil
      [] H|T then
	 F*H|{Mult T F}
      end
   end

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

   fun{Loop D L Lin}
      if D == 0 then nil
      else
	 case L
	 of nil then
	    {Loop D Lin Lin}
	 [] H|T then
	    H|{Loop D-1 T Lin}
	 end
      end
   end


   
   
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
	       D = D*44100.0
	    in
	       {AjouterMix {Loop D Echantillon Echantillon} Mix P2T T}
	    end
	 end
      end
   end
   
in
   {Browse {PartitionToTimedList [duration([a a a]  seconds:7.0)
				  stretch([a [a a]] factor:2.0)
				 ]
	   }
   }

   {Browse {Mix PartitionToTimedList [partition([a a a])
				     ]
	   }
   }

   {Browse {Mix PartitionToTimedList [repeat(amount:4
					     [partition([a a a]
						      )]
					    )
				     ]
	   }
   }

   {Browse {Mix PartitionToTimedList [reverse([partition([a a a])])]}}


   {Browse {Mix PartitionToTimedList [merge( [0.5#[partition([a a a])]
					      0.3#[partition([b b b b])]
					     ]
					   )
				     ]
	   }
   }
   {Browse {Mix PartitionToTimedList [loop(seconds:2.0 [partition([a a a])])]}}
   
					  
end



   

   


   