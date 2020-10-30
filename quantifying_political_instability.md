# Quantifying Political Instability
This document briefly describes a way to use our CAMEO-coded data in order to summarize the amount and intensity of conflict occurring in a region, then presents a method of utilizing this to visualize a prediction of temporal shifts in conflict within a region, and to compare conflict among regions. By quantifying conflict like this, this helps us accomplish our goal of predicting conflict in a way that can be compared to other regions.

### Goldstein Scale
The Goldstein scale, commonly used in data analysis using CAMEO-coded data, is a numerical mapping of CAMEO event types that corresponds to their perceived 'intensity' in terms of conflict or cooperation. It assigns each event type a number from -10.0 to 10.0, where negatives signify conflict events, and positive signify cooperation events. A score of 0.0 is neutral. Scores are given to both specific events and categories. Note that our data of interest is coded categories 14-20, which all have negative Goldstein scores, and as such, we are free to take the absolute value if necessary to ease analysis. A few examples of scores are given:  
| CAMEO code | Specific action | Goldstein score |
| --- | --- | --- |
| 014 | Consider policy option | 0.0 |
| 046 | Engage in negotiation | 7.0 |
| 1413 | Demonstrate for rights | -6.5 |

A complete mapping of the Goldstein scores to CAMEO events can be found [here](https://www.gdeltproject.org/data/lookups/CAMEO.goldsteinscale.txt), last updated 09/09/2020.  
Their respective CAMEO event code meanings are found [here](http://data.gdeltproject.org/documentation/CAMEO.Manual.1.1b3.pdf).
___
## Variables to Predict
These are recommendations for variables to predict to best analyze conflict in a region over time, and to summarize conflict to the reader.

#### Event volume
Because our data is CAMEO-coded, it is natural to predict the number of events of a specific action that occur in a region. This is what the [ViEWS model](https://www.pcr.uu.se/research/views/methodology/about_the_data/dependent-variables/) does, in addition to tracking estimated fatalities using the UCDP database. By tracking events of a specific action, we can analyze what events are most occurring in a region, or sum them to analyze by category or by total events in a region. Using these metrics we can compare 'how much is happening' in different regions and split by category of event.

#### Intensity
Using the Goldstein scale, we can calculate the average intensity of conflict in a region, and also the average intensity per category of conflict in order to distinguish between regions which may, for example, have differing intensities of protests.  
We adapt a formula used by [*Frank, et al.*](https://advances.sciencemag.org/content/advances/4/1/eaao5348.full.pdf) to measure the average Goldstein score for a collection of interaction CAMEO-coded events:
![LaTeX image of Goldstein averaging formula](https://latex2png.com/pngs/380953c58ed95ccff4c6b14901d0a53a.png)
*We omit the meaning of these variables here, but they can be found in the article.*
This formula is equivalent:
![LaTeX image of adapted Goldstein averaging formula](https://latex2png.com/pngs/d8e679f6c5d6ef2117063e97e60032f6.png)
For N total events, of CAMEO types i = 1,...,n, Goldstein scores g, event counts e, and probability of event type i P(i) in a set of events.  
While *Frank, et al.* apply this formula to analyzing the temporal changes in cooperation, we can use this to analyze changes in conflict within a region.  

It seems that a metric attempting to combine both event volume and intensity to output a single number measuring the conflict in a region would fail to be used as a comparative measure. We could simply output both, and use visualizations of these variables to see how regions compare in terms of conflict.
___
## Visualizations
These are possible comparative visualizations for the presentation of our findings/predictions using the aforementioned metrics.

#### Heat Maps
We have already discussed using heat maps to visualize the event volume in a region, as is done with the ViEWS model. Two separate heat maps could be made for each region at a given time: one to show the relative event volume ('how much is happening') and one to show the relative average intensity ('how bad is it').

#### Conflict-Time Graph
In order to better visualize the temporal change of conflict in a region, it would be best to take into account both the event volume and the average intensity of conflict in a region over time, to best compare 'how much is happening' and 'how bad it is' between 2 regions.  
To do this, we could plot the event volume (total number of events) against time, and color the resulting distribution with a gradient according to its average intensity score at a given time. An example plot is given:
![Example gradient-colored distribution plot](https://i.stack.imgur.com/4QQnx.jpg)
*Note: This is simply a random gradient-colored distribution plot, and was not made using our data.*
Imagining this was made using our data, an example interpretation may be that the region experienced a spike (high event volume signified by height of plot) in low-intensity conflict (colored orange) early on, and then steadily decreased in event volume (lowering height) while increasing in intensity (darkening of color).