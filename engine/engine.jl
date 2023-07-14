using Chess
using Chess.Book
using Infiltrator


# piece_values = (:BISHOP => 3, :KNIGHT => 3, :PAWN => 1, :QUEEN => 9, :ROOK => 5, :KING => 1000)
piece_values = Dict(BISHOP => 3, KNIGHT => 3, PAWN => 1, QUEEN => 9, ROOK => 5, KING => 1000)

function moves_to_square(B, sq)
    mvs = []
    for mv in moves(B)
        if to(mv) == sq
            push!(mvs, mv)
        end
    end
    return mvs
end

function most_value(B, ss)
    max_val = 0
    max_sq = nothing
    for sq in ss
        sq ∈ emptysquares(B) && continue
        p = pieceon(B, sq)
        pty = ptype(p)
        val = piece_values[pty]
        if val > max_val
            max_val = val
            max_sq = sq
        end
    end
    return max_sq
end

function attacked_but_undefended(board, color)
	attacker = -color  # The opposite color
	
	# Find all attacked squares
	attacked = SS_EMPTY  # The empty square set
	for s ∈ pieces(board, attacker)
		attacked = attacked ∪ attacksfrom(board, s)
	end
	
	# Find all defended squares
	defended = SS_EMPTY
	for s ∈ pieces(board, color)
		defended = defended ∪ attacksfrom(board, s)
	end
	
	# Return all attacked, but undefended squares containing pieces of
	# the desired color:
	attacked ∩ -defended ∩ pieces(board, color)
end

function find_hanging(B)
    # it doesn't check again if the piece is still hanging after the move
    colour = sidetomove(B)
    hanging_pieces = attacked_but_undefended(B, colour)
    if isempty(hanging_pieces)
        return []
    end
    # find the pieces on the squares

    
    # choose one at random
    mvs = []
    for sq = hanging_pieces
        for mv in moves(B)
            if from(mv) == sq #move the piece away
                push!(mvs, mv)
            end
        end
    end
    println("move hanging pieces: ", mvs)
    return mvs
end

function find_captures(B)
    colour = sidetomove(B)
    hanging_pieces = attacked_but_undefended(B, -colour)
    if isempty(hanging_pieces)
        return []
    end

    # choose one at random
    mvs = []
    for sq = hanging_pieces
        for mv in moves(B)
            if to(mv) == sq #move the piece away
                push!(mvs, mv)
            end
        end
    end
    println("capture hanging pieces: ", mvs)
    return mvs
end

function calculate_best_move(board_)
    # Return the best move as a string in UCI format

    # do a book move if possible
    book_moves = findbookentries(board_)
    if !isempty(book_moves)
        println("book move ", book_moves[1])
        mv = Move(book_moves[1].move)
        domove!(board_, mv)
        return mv |> tostring
    end

    # capture queen if possible
    c = sidetomove(board_)
    mvs = []
    for sq in queens(board_,-c)
        mvs = [mvs; moves_to_square(board_, sq)]
    end
    if !isempty(mvs)
        println("capture queen ", mvs[1])
        mv = mvs[1]
        domove!(board_, mv)
        return mv |> tostring
    end
    # do a capture if possible
    hanging = find_hanging(board_)
    if !isempty(hanging)
        println("move ", hanging[1])
        mv = hanging[1]
        domove!(board_, mv)
        return mv |> tostring
    end

    captures = find_captures(board_)
    if !isempty(captures)
        println("capture ", captures[1])
        mv = captures[1]
        domove!(board_, mv)
        return mv |> tostring
    end
    # checks
    # filter(m -> ischeck(domove(b, m)), moves(b))
    
    # do a random move
    mv = moves(board_) |> rand 
    domove!(board_, mv)
    println("random move ", mv)
    return mv |> tostring
end
    

# Wait for UCI commands from the GUI and process them
function process_commands()
    board = startboard()
    while true
        command = readline()
        # println(stderr,"Received command: $command")
        if command == "quit"
            break
        elseif command == "uci"
            println("id name EulerBot.jl")
            println("id author Caspar Gutsche")
            println("option name Move Overhead type spin default 30 min 0 max 1000")
            println("option name Threads type spin default 1 min 1 max 64")
            println("option name Hash type spin default 64 var 32 64 128 256 512")
            println("option name Ponder type check default false")
            println("option name SyzygyPath type string default <empty>")
            # Set other engine identification details
            println("uciok")
        elseif command == "isready"
            println("readyok")
        elseif command == "ucinewgame"
            # Reset the board to the starting position
            board = startboard()
        elseif startswith(command, "position")
            position_command = split(command, ' ')
            if length(position_command) > 2 && position_command[3] == "moves"
                mvs = position_command[4:end]
                board = startboard()
                domoves!(board, String.(mvs)...)
            else 
                board = startboard()
            end
            # (Code for parsing and updating the board goes here)
        elseif startswith(command, "go")
            # Calculate the best move using the engine's algorithms

            # Update the board based on the position command received earlier
            # (Code for updating the board goes here)
            best_move = calculate_best_move(board)
            println("bestmove $best_move")
        elseif startswith(command, "setoption")
            # Handle options as needed
            # (Code for handling options goes here
        elseif startswith(command, "move overhead")
            # Handle overhead moves as needed
            # (Code for handling overhead moves goes here)
            println(stderr,"Overhead move: $command")
            println("option name Move Overhead type spin default 30 min 0 max 1000")
        # Handle other UCI commands as needed
        # setoption name Hash value 32
        else
             println(stderr,"Unknown command: $command")
        end
    end
end

# Start processing UCI commands
process_commands()
