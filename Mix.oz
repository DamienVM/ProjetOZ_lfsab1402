declare
fun{Mix P2T Music}
   case Music
   of nil then nil
   else H|T then
      local
	 fun {Ajouter P K}
	    case P
	    of nil then {Mix P2T K}
	    [] H|T then H|{Ajouter T K}
	    end
	 end
      in
	 case H
	 of samples(Sample) then
	    {Ajouter Sample T}
	    
	 [] partition(Part)
	    local
	       P = {P2T Part}
	       fun{Hauteur N}
		  case N
		  of note(name:N sharp:S octave:O duration:D instrument:I)
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
		     in
			12.0*(N.octave-4)+{NoteToNumb N}-10
		     end
		  end
	       end
	       F
	    in
	       case P
	       of nil then nil
	       [] H|T then
		  case H of K|J then
		  end
		  

	       [] note(name:N sharp:S octave:O duration:D instrument:I)
	       then
		  local
		     
		     H F 
		  in
		     H = { Hauteur N}
		     F = {Pow 2 (H/12.0)} *440
		  end
		  
		    
		  

	    end
	 
	 
      
end
	 end
      end
   end
end


{Browse {Pow 2 2}}
{Browse 1}

	    