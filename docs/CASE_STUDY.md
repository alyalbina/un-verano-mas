# Designing a road worth remembering

**Un Verano Más · product and game design case study**  
Concept and creative direction: **Albina Urubkina**  
Current artifact: **playable Godot prototype, first chapter v0.8**

![The workshop and the harbor](media/chapter-one-preview.png)

## The idea

Turn a summer journey through Spain into an adventure that preserves small, personal moments: a catamaran's black net over the water, ice cream after a walk through Marbella, a lost camera at a reservoir, music in Ronda and an evening above Madrid.

The full route is a narrative plan. The current prototype reaches the harbor before the first boat trip.

## The experience problem

An illustrated collection of places can feel like a slideshow. The design goal was to make the player discover connections between places, try understandable actions and move through a continuous journey.

Lucia finds a photograph of Carmen's courtyard with a door that no longer exists. In direct sunlight the picture casts the missing door's shadow. Zhorik notices its movement first. The mystery begins with a contradiction the player can see and investigate.

## Three decisions that shape the prototype

### 1. Puzzles change the location itself

The missing door depends on sunlight, a photograph, laundry and a floor shadow. A street opens through still water and a changing viewpoint. A fountain carries an echo through a visible water route. The repaired frame must connect to an ordinary map before the journey can continue.

Experimenting produces observable feedback: a slipping belt, divided flow, a broken reflection or light returning to the beginning. Failure preserves the player's ability to try again.

### 2. Exploration has room to breathe

The courtyard, street and plaza are three screens wide. A following camera supports long walks without shrinking the characters. Optional observations add food, shade, coastal views and small pauses, while the main puzzles stay together in the central area.

### 3. Memories enter through actions and details

The harbor introduces the catamaran and the promise of ice cream in Marbella. Later planned chapters use the reservoir, a fallen camera, a floating mattress, watermelon, Ronda's musicians and Madrid's moving clock figures. These are recognizable anchors for the story; they are not claimed as implemented gameplay yet.

## How the prototype is organized

Progression belongs to a canonical state object. Scene modules render that state and handle local interactions. This supports revisits, reversible experiments, ordered prerequisites and migration from earlier saves. Character origins are at their feet, and horizontal camera movement is separated from the screen-fixed interface.

The project includes rule tests, startup tests and live-input playthrough scripts. The [v0.8 validation record](reboot/VALIDATION_V0_8.md) documents 315 successful checks from the development build. Player-perceived difficulty and completion time still require external playtesting.

## What changed through iteration

Early feedback identified weak boat composition and inconsistent character scale. The prototype subsequently moved toward a shared visual scale, grounded character placement and a quieter interface. Another iteration expanded the locations because the scenes felt too short. The current chapter ends at the real harbor and sets up the next step of the journey.

## Scope and authorship

This is an independent prototype developed with AI-assisted coding and generated illustration assets. The repository preserves the [asset provenance](reboot/ASSET_PROVENANCE.md), [new image prompts](reboot/ASSET_PROMPTS_V0_8.md), design documents and source code. It does not use artwork from Lost in Play.

The next playable milestone is the boat trip and Marbella. Later planned stops include the reservoir, Ronda, Tarifa, Seville and Madrid. Final character animation, music and external playtesting remain further production work.
