

write-host "Welcome to 2048!"

$sideLength = 4

function Write-Board($board) {

    function Get-MaxTileLength ($board) {

        function Get-NumberLength ($number) {
            $digits = 0
            while ($number) {
                $number = [math]::Floor($number / 10)
                $digits += 1
            }
            return $digits
        }

        $lengths = @()

        $max = -1

        for ($row = 0; $row -lt $sideLength; $row += 1) {
            for ($col = 0; $col -lt $sideLength; $col += 1) {
                $digits = Get-NumberLength($board[$row * $sideLength + $col])
                if ($digits -gt $max) {
                    $max = $digits
                }
                $lengths += $digits
            }
        }
        return ($lengths, $max)
    }

    $tileLengthsAndMax = Get-MaxTileLength($board)
    $tileLengths = $tileLengthsAndMax[0]
    $max = $tileLengthsAndMax[1]


    $dashes = "-" * $max
    $dashTile = "--$dashes`-"
    $line = $dashTile * $sideLength
    Write-Host "$line`-"

    for ($row = 0; $row -lt $sideLength; $row += 1) {
        for ($col = 0; $col -lt $sideLength; $col += 1) {
            $tile = $board[$row * $sideLength + $col]

            $tileLength = $tileLengths[$row * $sideLength + $col]
            $diff = $max - $tileLength

            $tileSpace = ""
            for ($spacing = 0; $spacing -lt $diff; $spacing += 1) {
                $tileSpace += " "
            }

            $tile = if ($tile -eq 0) {
                ""
            }
            else {
                $tile
            }

            $tileDisplay = "| $tileSpace$tile "
            Write-Host $tileDisplay -NoNewline
        }
        Write-Host "|"
    }
    Write-Host "$line`-"
}

function New-Tile ($board) {
    $empties = @()
    for ($index = 0; $index -lt ($sideLength * $sideLength); $index += 1) {
        if ($board[$index] -eq 0) {
            $empties += $index
        }
    }

    
    if ($empties.Length -gt 0) {
        $emptiesIndex = Get-Random -Minimum 0 -Maximum $empties.Length
        $tileIndex = $empties[$emptiesIndex]
        $isFour = Get-Random -Minimum 0 -Maximum 2
        $board[$tileIndex] = if ($isFour -eq 1) {
            4
        }
        else {
            2
        }
    }

    return $board
}

function New-Board {
    $board = @()
    for ($index = 0; $index -lt ($sideLength * $sideLength); $index += 1) {
        $board += 0
    }
    $board = New-Tile($board)
    $board = New-Tile($board)
    return $board
}


$board = New-Board
# $board = @(
#     8,8,8,8,
#     8,8,8,8,
#     8,8,8,8,
#     8,8,8,8
# )

function Write-Turn ($board, $helping) {
    Write-Board($board)
    Write-Host("Press 'h' for help:")
    if ($helping) {
        Write-Host("  - 'Up' to move up`n  - 'down' to move down`n  - 'left' to move left`n  - 'right' to move the right`n  - 'r' to restart`n  - 'q' to quit")

    }

}




# Write-Turn($board)
Write-Turn -board $board

function Push-Turn ($board) {

    $last = $board | foreach { $_ }

    $key = $Host.UI.RawUI.ReadKey()[0]

    $key = if ($key.VirtualKeyCode -eq 38) {
        'Up'
    }
    elseif ($key.VirtualKeyCode -eq 37) {
        'Left'
    }
    elseif ($key.VirtualKeyCode -eq 40) {
        'Down'
    }
    elseif ($key.VirtualKeyCode -eq 39) {
        'Right'
    }
    else {
        $key.Character
    }

    cls


    function Collapse-Stack ([Array]$stack) {
        $ns = $stack | foreach { $_ }
        $index = 0
        
        # Loop for pushing everything to the left
        while ($index -lt $stack.Length - 1) {
            if ($ns[$index] -eq 0) {
                $off = 1
                while ($ns[$index + $off] -eq 0) {
                    $off += 1
                }
                if ($index + $off -lt $ns.Length) {
                    $ns[$index] = $ns[$index + $off]
                    $ns[$index + $off] = 0
                }
            }
            $index += 1
        }

        # loop for combining
        $lp = 0
        $rp = 1
        while ($rp -lt $ns.Length) {
            if ($ns[$lp] -eq $ns[$rp]) {
                $ns[$lp] *= 2;
                
                # push everything over
                $off = $rp
                while ($off -lt $ns.Length - 1) {
                    $ns[$off] = $ns[$off + 1]
                    $off += 1
                }
                # Set the end to 0
                $ns[$off] = 0
                
                
            }
            $lp = $rp
            $rp += 1
        }

        return $ns
    }

    $playing = 'playing'
    $helping = $false
    $valid = $true

    if ($key -eq 'Up') {
        for ($col = 0; $col -lt $sideLength; $col += 1) {
            # pack the stack
            $stack = @()
            for ($row = 0; $row -lt $sideLength; $row += 1) {
                $stack += $board[$row * $sideLength + $col]
                $board[$row * $sideLength + $col] = 0
            }
            # collapse the stack
            $ns = Collapse-Stack $stack
            # unpack the stack
            for ($row = 0; $row -lt $sideLength; $row += 1) {
                $board[$row * $sideLength + $col] = $ns[$row]
            }
        }
    }
    ElseIf ($key -eq 'Down') {
        for ($col = 0; $col -lt $sideLength; $col += 1) {
            # pack the stack
            $stack = @()
            for ($row = $sideLength - 1; $row -ge 0; $row -= 1) {
                $stack += $board[$row * $sideLength + $col]
                $board[$row * $sideLength + $col] = 0
            }
            # collapse the stack
            $ns = Collapse-Stack $stack
            # unpack the stack
            for ($row = $sideLength - 1; $row -ge 0; $row -= 1) {
                $board[$row * $sideLength + $col] = $ns[$sideLength -1- $row]
            }
        }
    }
    ElseIf ($key -eq 'Left') {
        for ($row = 0; $row -lt $sideLength; $row += 1) {
            # pack the stack
            $stack = @()
            for ($col = 0; $col -lt $sideLength; $col += 1) {
                $stack += $board[$row * $sideLength + $col]
                $board[$row * $sideLength + $col] = 0
            }
            # collapse the stack
            $ns = Collapse-Stack $stack
            # unpack the stack
            for ($col = 0; $col -lt $sideLength; $col += 1) {
                $board[$row * $sideLength + $col] = $ns[$col]
            }
        }
    }
    ElseIf ($key -eq 'Right') { 
        for ($row = 0; $row -lt $sideLength; $row += 1) {
            # pack the stack
            $stack = @()
            for ($col = $sideLength - 1; $col -ge 0; $col -= 1) {
                $stack += $board[$row * $sideLength + $col]
                $board[$row * $sideLength + $col] = 0
            }
            # collapse the stack
            $ns = Collapse-Stack $stack
            # unpack the stack
            for ($col = $sideLength - 1; $col -ge 0; $col -= 1) {
                $board[$row * $sideLength + $col] = $ns[$sideLength -1- $col]
            }
        }
    }
    ElseIf ($key -eq 'q' -or $key -eq 'Q') {
        $playing = 'quit'
        Write-Host "Quitting . . ."
    }
    ElseIf ($key -eq 'h' -or $key -eq 'H') {
        $helping = $true
    }
    Else {
        $valid = $false
    }

    function Can-Move ($board) {

        #find missing
        $empties = $board | where { $_ -eq 0 }
        if ($empties.Length -gt 0) {
            return $true
        }

        #check combinable neighbors
        for ($row = 0; $row -lt $sideLength; $row += 1) {
            for ($col = 0; $col -lt $sideLength; $col += 1) {
                $tile = $board[$row * $sideLength + $col]
                
                #up
                if ($row -ne 0) {
                    $up = $board[($row - 1) * $sideLength + $col]
                    if ($tile -eq $up) {
                        return $true
                    }
                }
                #down
                if ($row -ne $sideLength - 1) {
                    $down = $board[($row + 1) * $sideLength + $col]
                    if ($tile -eq $down) {
                        return $true
                    }
                }
                #left
                if ($col -ne 0) {
                    $left = $board[$row * $sideLength + $col - 1]
                    if ($tile -eq $left) {
                        return $true
                    }
                }
                #right
                if ($col -ne $sideLength - 1) {
                    $right = $board[$row * $sideLength + $col + 1]
                    if ($tile -eq $right) {
                        return $true
                    }
                }
            }
        }


        return $false
    }


    if ($valid -and $playing -eq 'playing') {
        # only add a tile when the board state has changed
        
        $changed = $false
        for ($index = 0; $index -lt ($sideLength * $sideLength); $index += 1) {
            if ($last[$index] -ne $board[$index]) {
                $changed = $true
                break
            }
        }
        if ($changed) {
            $board = New-Tile $board
        }


        $playing = Can-Move $board
        if (-not $playing) {
            $playing = 'lost'
            Write-Host "You lose!"
        }
    }


    Write-Turn -board $board -helping $helping

    return ($playing, $board)
}

while ($true) {
    do {
        $playingAndBoard = Push-Turn $board
        $playing = $playingAndBoard[0]
        $board = $playingAndBoard[1]
    } while ($playing -eq 'playing')

    if ($playing -eq 'quit') {
        break
    }
    elseif ($playing -eq 'lost') {
        Write-Host "Play Again?`n  y for yes`n  n for no"
        $quit = $false
        $valid = $false
        while (-not $valid) {
            $key = $Host.UI.RawUI.ReadKey()[0].Character
            if ($key -eq 'y' -or $key -eq 'Y') {
                $board = New-Board
                $valid = $true
            }
            elseif ($key -eq 'n' -or $key -eq 'N') {
                $valid = $true
                $quit = $true
            }
        }
        if ($quit) {
            break
        }
    }
}

# $key = $Host.UI.RawUI.ReadKey()
