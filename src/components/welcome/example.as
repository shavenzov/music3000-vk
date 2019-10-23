import components.welcome.Slides;
import components.welcome.events.GoToEvent;
import components.welcome.events.OpenProjectEvent;

import mx.events.CloseEvent;

private function backClick() : void
{
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.VIDEO, 'firstTime' ) );
}

private function onOpen( e : OpenProjectEvent ) : void
{
	if ( ( currentState == 'normal' ) || ( currentState == 'break' ) )
	{
		e.fromIndex = 3;
	}
	
	dispatchEvent( e );
}

private function videoClick() : void
{
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.VIDEO, 'normal' ) );
}

private function closeClick() : void
{
	dispatchEvent( new CloseEvent( CloseEvent.CLOSE ) );
}