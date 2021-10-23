# LAMMPS_shell
some small scripts

# you can use this after msi2lmp.exe
msi2lmp.exe filename -i -class 1 -frv cvff   
data_modify.sh filename.data   

Then you will get two files: filename.data, nfilename.data.   
The atom_style in the filename.data is full, and in the nfilename.data is charge.  
