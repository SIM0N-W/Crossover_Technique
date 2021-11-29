# Plotable
<p align="center">
 <img src=https://user-images.githubusercontent.com/76114144/142266780-926358f2-1c51-4b01-878f-d7a03e4e2d58.png />
</p>

### *A program to determine the degree of axonal cross-over.*

The program we designed will help users (clinicians, researchers, and electromyographers), perform geometric nerve conduction waveforms subtractions with ease.
The purpose was to interrogate the degree of nerve cross-over. Ranging from natural (Martin-Gruber Anastomosis) or artifical (Nerve Transfers) nerve cross-over applications.

## I. Accessing Plotable

### Download the files by pressing the "Code" (green) button, then "Download ZIP"<br/>
#### For a video guide to installing Plotable, visit:<br/>

***One can open the program one of three ways:***

#### A)	Have MATLAB 

>   **1)**	Install **Plotable - MATLAB.mlappinstall** as a MATLAB App under the “Apps” tab in MATLAB.<br/>
>   **2)**	Open the development version: **Plotable.mlapp** (*Development Folder*) 

#### B)	Do not have MATLAB

>   **3)**	Install Plotable as a standalone app in the provided files for Windows and MacOS.<br/>
> **Plotable Installer - Windows**<br/>
> **Plotable Installer - MacOS**<br/>

<br/>

The original code for the Plotable can be found in the - *Development Folder* --> **Plotable.mlapp**.<br/>
>Open with *MATLAB App Designer* and enter "code view".

## II. Using Plotable

*(“” — quotations refer to an element found in the program.)*
1)	Select a “Sampling Rate” (kHz) using the knob.
2)	Select the respective CMAPs obtained from select anatomical locations.
3)	Adjust the gain (mV/d) used in recording the waveforms.
4)	“Plot Raw Waveforms”.
a.	Plots each of the waveform’s amplitude vs time at an optimal scale to locate the true onset of each CMAP.
5)	Locate the onset points for each waveform.
6)	Input the x-value onset points for each waveform into the boxes.
7)	“Plot Shifted Waveform”.
a.	Onset aligns the median wrist to elbow and the ulnar wrist to elbow CMAPs in 2 separate graphs scaled. A green digital subtraction plot is overlayed.
8)	Make finer changes in onset values until a favourable plot of the geometric subtraction is obtained.
9)	Once satisfied with the digital subtraction, “Analyze Waveforms”.
a.	The negative peak amplitude and negative peak area are displayed for the median and ulnar subtraction on separate graphs.
10)	To accommodate larger or smaller CMAPs, the scale can be changed by opening the Plotable.mlapp file in MATLAB App Designer and entering ‘code view’. 

