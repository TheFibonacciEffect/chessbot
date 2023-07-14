To initialize the submodule to interact with LiChess use
        
        git submodule init

and 
        
        git submodule update

you can play with stockfish, to do it
compile stockfish using
        cd src
        make -j build ARCH=x86-64-modern
        mv stockfish ../stockfish

otherwise there is an own engine implementation in julia

to play a game use

        python3 lichess-bot.py
