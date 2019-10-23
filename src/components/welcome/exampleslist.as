import classes.api.MainAPI;
import classes.api.data.ProjectInfo;

import components.welcome.events.OpenProjectEvent;

import mx.collections.ArrayCollection;

private var _showHeader : Boolean = true;

/**
 * Выбранный проект 
 */
public var selectedProject : ProjectInfo;

private function creationComplete() : void
{
	projects.dataProvider = new ArrayCollection( MainAPI.impl.examples );
}

private function selectProject() : void
{
	selectedProject = projects.selectedItem;
	dispatchEvent( new OpenProjectEvent( OpenProjectEvent.OPEN, selectedProject ) );
}

public function get showHeader() : Boolean
{
	return _showHeader;
}

public function set showHeader( value : Boolean ) : void
{
	_showHeader = value;
	invalidateProperties();
}

override protected function commitProperties() : void
{
	super.commitProperties();
	
	header.visible = header.includeInLayout = _showHeader;
}