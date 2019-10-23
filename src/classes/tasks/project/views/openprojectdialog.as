import mx.events.CloseEvent;

private function cancelClick() : void
{
	dispatchEvent( new CloseEvent( CloseEvent.CLOSE ) );
}