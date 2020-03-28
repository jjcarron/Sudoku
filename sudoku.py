# -*- coding: utf-8 -*-
"""
Created on Sun May  7 17:44:48 2017

@author: jjcarron
"""
import sys 
import re
import math
import time
import copy

class SudokuFile():
               
    def __init__(self, filename):
        self.name = filename
        with open(filename) as myfile:
            sudokuStr = "".join(line.rstrip() for line in myfile)
        myfile.close()
       
        sudokuStr.capitalize
        sudokuStr = re.sub(r"[\,\;,\t,\ ]+", "", sudokuStr)        
        self.alpha_sudoku = list(sudokuStr)
        
    def sudoku_lst(self):
        return [int(x, 16) for x in self.alpha_sudoku]

class Cell ():
    
    def __init__(self):
        self.row = 0
        self.col = 0
        self.mCell = 0
        self.value = 0

    def __str__(self):
        return  'row={} col={} mCell={} Value={}'.format (self.row, self.col, self.mCell, self.value)

class Group ():

    def __init__(self, cells):
        self.cells = cells
        self.possibleVal = {x for x in range (1, len(cells)+1)}

    def defined (self):
        return {x.value for x in self.cells} - {0}

    def undefined (self):
        return self.possibleVal - self.defined()

    @property
    def possible(self):
        return self.undefined()

    def __str__(self):
        return '{} {} {}'.format ([hex(x.value)[2:] for x in self.cells], self.defined(), self.undefined())

class Sudoku ():
    iteration_Loops = 0
    unique_iteration_Loops = 0

    def __init__(self, sudoku):
        self.size = math.floor(math.sqrt(len(sudoku)))
        self.nbCells = self.size ** 2
        self.macroCellSize = math.floor(math.sqrt(self.size))
        self.nbMacroCells = self.macroCellSize ** 2
        self.groupTotal = self.size * (self.size+1) // 2
        self.grandTotal = self.size * self.groupTotal
        self.cells = []
        self.cols = []
        self.rows = []
        self.mCells = []
        self.possibleVal = {x for x in range (1, self.size+1)}

        if  ( self.nbCells != len(sudoku) or  (self.macroCellSize ** 2 != self.size)):
            sys.exit("The file %s has a wrong size or is not a sudoku file.\n" % sys.argv[1])

        #initialize Cells
        pos = 0
        for r in range(0, self.size):
            for c in range (0,self.size):
                cell = Cell()
                cell.col = c
                cell.row = r
                cell.mCell = (r // self.macroCellSize) * self.macroCellSize + (c // self.macroCellSize)
                cell.value = sudoku[pos]

                self.cells.append(cell)
                pos += 1
        self.init_Groups()

    def cellPos(self, cell):
        return cell.row * self.size + cell.col

    def sudoku_lst(self):
        return [x.value for x in self.cells]

    def init_Groups(self):
        # initialize cols
        for c in range (0, self.size):
            cols = []
            for r in range(0, self.size):
                pos = r * self.size + c
                cols.append(self.cells[pos])
            cols = Group(cols)
            self.cols.append(cols)

        # initialize rows
        for r in range (0,self.size):
            rows = []
            for c in range(0, self.size):
                pos = r * self.size + c
                rows.append(self.cells[pos])
            rows = Group(rows)
            self.rows.append(rows)


        # initialize MacroCells
        for R in range (0, self.macroCellSize):
            for C in range (0, self.macroCellSize):
                Cells = []
                for r in range (self.macroCellSize * R, self.macroCellSize * R + self.macroCellSize ):
                    for c in range (self.macroCellSize * C , self.macroCellSize * C + self.macroCellSize ):
                        pos = r * self.size + c
                        Cells.append(self.cells[pos])
                mCells = Group(Cells)
                self.mCells.append(mCells)

    def possible(self, cell):
        return self.cols[cell.col].possible & self.rows[cell.row].possible & self.mCells[cell.mCell].possible

    def total (self):
        return sum(self.sudoku_lst())

    def display(self):
        i=0
        self.alpha_sudoku = [hex(x)[2:] for x in self.sudoku_lst() ]
        for e in self.alpha_sudoku:
            i += 1
            print (e, end=" "),
            if (i % self.size) == 0:
               print ("")

    @staticmethod
    def unique_iterations():
        Sudoku.unique_iteration_Loops += 1
        return Sudoku.unique_iteration_Loops

    @staticmethod
    def iterations():
        Sudoku.iteration_Loops += 1
        return Sudoku.iteration_Loops

    def reOrderSudoku(self):
        self.cells.sort(key=lambda c: c.row * self.size + c.col, reverse = False)

    def completed(self):
        for g in self.cols:
            if sum([x.value for x in g.cells]) != self.groupTotal: return False
        for g in self.rows:
            if sum([x.value for x in g.cells]) != self.groupTotal: return False
        for g in self.mCells:
            if sum([x.value for x in g.cells]) != self.groupTotal: return False
        return True

    def restoreCellsValues(self, cellsValues):
        for i in range(0, self.nbCells):
            self.cells[i].value = cellsValues[i]

    def getFirstEmptyCell(self, pos):
        for i in range(pos, self.nbCells):
            if self.cells[i].value == 0:
                return True, i
        return False, pos

    def solve_UniqueInGroup(self, group):
        Changed = False
        cell = Cell()
        for e in group:
            for n in e.possible:
                nPos = 0
                for c in e.cells:
                    if c.value == 0 and n in self.possible(c):
                        nPos += 1
                        cell = c
                        if nPos > 1:
                            break
                if nPos == 1 and cell.value == 0:
                   cell.value = n
                   Changed = True
        return Changed

    def solve_UniqueCell(self):
        Changed = False
        for cell in self.cells:
            if cell.value == 0 and len(self.possible(cell)) == 1:
               cell.value = list(self.possible(cell))[0]
               Changed = True
        return Changed

    def solve_unique(self):
        self.unique_iterations()
        Changed = False

        # check unique possibility in cell
        Changed = self.solve_UniqueCell()

        # check unique pos of number in groups
        Changed = Changed or self.solve_UniqueInGroup(self.cols)
        Changed = Changed or self.solve_UniqueInGroup(self.rows)
        Changed = Changed or self.solve_UniqueInGroup(self.mCells)

        return Changed

    def solve_allUniques(self):
        while self.solve_unique():
            pass

    def solve(self, pos):
        Sudoku.iterations()
        self.solve_allUniques()
        (found, pos) = self.getFirstEmptyCell(pos)
        if not found:
            if self.completed():
                return True
            else:
                return False

        cellsValues = self.sudoku_lst()
        for i in self.possible(self.cells[pos]):
            self.cells[pos].value = i
            if self.solve(pos):
                return True
            self.restoreCellsValues(cellsValues)

        return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit("Usage: %s <sudoku file>\n" % sys.argv[0])

    sudokuFile = SudokuFile(sys.argv[1])
    if len(sys.argv) > 2 :
        n = int (sys.argv[2])
    else:
        n=1

    start = time.time()

    for i in range(0, n):
        sudoku = Sudoku(sudokuFile.sudoku_lst())
        if not sudoku.solve(0) :
            print('sudoku is not solvable')
            break

    elapsed = (time.time() - start)

    tsolve = elapsed / n
    loops = sudoku.iteration_Loops // n
    unique_Loops = sudoku.unique_iteration_Loops // n
    print ('solved in {:0.6f} seconds'.format(tsolve))
    print ('bruteforce iteration loops = {}'.format(loops))
    print ('unique iteration loops = {}'.format(unique_Loops))
    print ()
    sudoku.reOrderSudoku()
    sudoku.display()
exit

