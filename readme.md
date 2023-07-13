To initialize the submodule to interact with LiChess use
        git submodule init

and 
        git submodule update

compile stockfish using
        cd src
        make -j build ARCH=x86-64-modern
        mv stockfish ../stockfish

to play a game use

        python3 lichess-bot.py