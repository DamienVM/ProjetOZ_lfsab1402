declare
fun {PartitionToTimedList Partition}
   case Partition
   of nil then nil
   [] H|T then
      local
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
      in
	 if {IsExtanded H} then
	    H|{PartitionToTimedList T}
	 else
	    local
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

	    in
	       case H
	       of K|J then {ChordToExtended H}|{PartitionToTimedList T}
	       [] Name#Octave then {NoteToExtended H}|{PartitionToTimedList T}
	       else
		  local
		     
		     fun{Ajouter P K}
			case P
			of nil then {PartitionToTimedList K}
			[] H|T then H|{Ajouter T K}
			end
		     end
		     
		     Transformation = {Label H}

		  in
		     if Transformation == transpose
			orelse Transformation == drone
			orelse Transformation == duration
			orelse Transformation == stretch
		     then
			case H
			of transpose(semitones:S Part)then
			   local
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
			      P
			      NP
			   in
			      P = {PartitionToTimedList Part}
			      NP = {Transpose P S}
			      {Ajouter NP T}
			      
			   end
			   
			[] drone(note:N amount:A) then
			   local
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
			      NP
			   in
			      NP = {Drone {ExtendN N} A nil}
			      {Ajouter NP T}
			   end
			   
			elseif Transformation == stretch orelse Transformation == duration then
			   local
			      fun{Stretch P F}
				 local
				    fun{StretchNote N F}
				       case N
				       of H|T then
					  local
					     fun {StretchChord C F}
						case C
						of nil then nil
						[] H|T then {StretchNote N F}|{StretchChord T F}
						end
					     end
					  in
					     {StretchChord H F}
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
			   in
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
				     N = {PartitionToTimedList Part}
				     NP
				  in
				     NP = {Duration N S}
				     {Ajouter NP T}
				  end	  
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
   end
end






{Browse {PartitionToTimedList [duration([a a a]  seconds:7.0)]}}


