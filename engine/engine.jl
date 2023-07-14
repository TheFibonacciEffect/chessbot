using Chess
using Chess.Book
using Infiltrator
using Random

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

# function most_value(B, ss)
#     max_val = 0
#     max_sq = nothing
#     for sq in ss
#         sq ∈ emptysquares(B) && continue
#         p = pieceon(B, sq)
#         pty = ptype(p)
#         val = piece_values[pty]
#         if val > max_val
#             max_val = val
#             max_sq = sq
#         end
#     end
#     return max_sq
# end

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

# function find_hanging(B)
#     # it doesn't check again if the piece is still hanging after the move
#     colour = sidetomove(B)
#     hanging_pieces = attacked_but_undefended(B, colour)
#     if isempty(hanging_pieces)
#         return []
#     end
#     # find the pieces on the squares

    
#     # choose one at random
#     mvs = []
#     for sq = hanging_pieces
#         for mv in moves(B)
#             if from(mv) == sq #move the piece away
#                 push!(mvs, mv)
#             end
#         end
#     end
#     println("move hanging pieces: ", mvs)
#     return mvs
# end

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
    return mvs
end

function find_checks(b)
    checks = filter(m -> ischeck(domove(b, m)) && isempty(attacked_but_undefended(domove(b, m),sidetomove(b))), moves(b))
    return checks
end

function find_defense(b)
    threats = filter(m -> !isempty(attacked_but_undefended(domove(b, m),-sidetomove(b))) && isempty(attacked_but_undefended(domove(b, m),sidetomove(b))), moves(b))
    return threats
end

# function calculate_best_move(board_)
#     # Return the best move as a string in UCI format

#     # do a book move if possible
#     book_moves = findbookentries(board_)
#     if !isempty(book_moves)
#         println("book move ", book_moves[1])
#         mv = Move(book_moves[1].move)
#         domove!(board_, mv)
#         return mv |> tostring
#     end

#     # capture queen if possible
#     c = sidetomove(board_)
#     mvs = []
#     for sq in queens(board_,-c)
#         mvs = [mvs; moves_to_square(board_, sq)]
#     end
#     if !isempty(mvs)
#         println("capture queen ", mvs[1])
#         mv = mvs[1]
#         domove!(board_, mv)
#         return mv |> tostring
#     end
#     # do a capture if possible
#     captures = find_captures(board_)
#     if !isempty(captures)
#         println("capture ", captures[1])
#         mv = captures[1]
#         domove!(board_, mv)
#         return mv |> tostring
#     end

#     # do check if possible

#     checks = find_checks(board_)
#     if !isempty(checks)
#         mv = rand(checks)
#         println("check ", mv)
#         domove!(board_, mv)
#         return mv |> tostring
#     end
    
#     # find threats
#     threats = find_attacks(board_)
#     if !isempty(threats)
#         mv = rand(threats)
#         println("threat ", mv)
#         domove!(board_, mv)
#         return mv |> tostring
#     end
    
#     hanging = find_hanging(board_)
#     if !isempty(hanging)
#         println("move ", hanging[1])
#         mv = hanging[1]
#         domove!(board_, mv)
#         return mv |> tostring
#     end

#     # do a random Move
#     mv = moves(board_) |> rand 
#     domove!(board_, mv)
#     println("random move ", mv)
#     return mv |> tostring
# end


function evaluate_position(board)
    # Function to evaluate the current position and return a score
    # based on factors like piece values, board control, etc.
    # Implement your own evaluation logic here.
    val = 0
    c = sidetomove(board)
    for s ∈ pieces(board, c)
        val += piece_values[ptype(pieceon(board, s))]
    end
    for s ∈ pieces(board, -c)
        val -= piece_values[ptype(pieceon(board, s))]
    end
    if ischeck(board)
        val -= 5
    end
    hanging_pieces = attacked_but_undefended(board, c)
    if !isempty(hanging_pieces)
        val -= 10
    end
    if ischeckmate(board)
        val -= Inf
    end
    return val
end

function alpha_beta(board, depth, alpha, beta, maximizing_player)
    global neval += 1
    if depth == 0 || isterminal(board)
        return evaluate_position(board)
    end
    
    if maximizing_player
        max_eval = -Inf
        for move in moves(board)
            u = domove!(board, move)
            eval = alpha_beta(board, depth - 1, alpha, beta, false) #thre might be a minus sign missing here
            undomove!(board, u)
            max_eval = max(max_eval, eval)
            alpha = max(alpha, max_eval)
            # if beta < max_eval
            #     break
            # end
        end
        return max_eval
    else
        min_eval = Inf
        for move in moves(board)
            u = domove!(board, move)
            eval = -alpha_beta(board, depth - 1, alpha, beta, true) #thre might be a minus sign missing here
            undomove!(board, u)
            min_eval = min(min_eval, eval)
            beta = min(beta, eval)
            # if min_eval < alpha
            #     break
            # end
        end
        return min_eval
    end
end

function find_best_move(board)
    best_eval = -Inf
    best_move = nothing
    # for move in union(find_defense(board),find_captures(board),find_checks(board), shuffle(moves(board)))
    for move in shuffle(moves(board))
        u = domove!(board, move)
        eval = alpha_beta(board, MAX_DEPTH, -Inf, Inf, false)
        undomove!(board, u)
        if eval > best_eval
            best_eval = eval
            best_move = move
        end
    end
    println("best eval: ", best_eval)
    return best_move |> tostring
end

# function generate_moves(board)
#     # Function to generate all possible legal moves on the current board.
#     # Implement your own move generation logic here.
#     return []
# end

# function make_move(board, move)
#     # Function to apply the given move on the board.
#     # Implement your own move application logic here.
# end

# function unmake_move(board, move)
#     # Function to undo the given move on the board.
#     # Implement your own move undo logic here.
# end


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
            println("current evaluation", evaluate_position(board))
            best_move = find_best_move(board)
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

const MAX_DEPTH = 1
neval = 0
debug = true
if debug
# @show board = fromfen("rnbqkbnr/pp1p1ppp/8/3pp3/3P4/5Q2/PPPP1PPP/RNB1KBNR w KQkq - 0 1")
    # @show board = fromfen("r1bqk2r/pp3pbp/3pp1p1/2p4P/2PnP3/3P2P1/PP2NPB1/R1BQK2R b KQkq - 1 11") 
    print("paste fen: ") # 8/1k6/3q4/4P3/5P2/2K5/8/8 b - - 0 1
    @show board = fromfen(readline()) 
    @show evaluate_position(board)
    @show find_best_move(board)
    @show neval
    
    find_defense(board)
    find_captures(board)
    find_checks(board)
    attacked_but_undefended(board, sidetomove(board)) # hanging pieces
    attacked_but_undefended(board, -sidetomove(board)) # threats
    function find_moves_to_squareset(b,ss)
        ml = []
        for sq in ss
            for mv in moves(b)
                if to(mv) == sq
                    push!(ml, mv)
                end
            end
        end
        return ml
    end
    find_moves_to_squareset(board, attacked_but_undefended(board, -sidetomove(board))) # moves that capture undefended pieces

else
    process_commands()
end