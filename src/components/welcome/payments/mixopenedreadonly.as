import classes.api.errors.APIError;
import classes.api.events.LimitationsEvent;
import classes.tasks.project.ProjectTask;

import components.welcome.Slides;
import components.welcome.events.BackEvent;
import components.welcome.events.GoToEvent;

import flashx.textLayout.conversion.TextConverter;

import mx.events.CloseEvent;

private function onShow() : void
{
	var pr : ProjectTask = ApplicationModel.project;
	
	var str : String = 'Микс <i>' + pr.info.name + '</i> открыт только для просмотра. Любые изменения не смогут быть сохранены т.к. ';
	
	if ( pr.info.readonly )
	{
		str += 'автор запретил редактирование.';
		currentState = 'perDayExceeded';
	}
	else
	{
		str += LimitationsEvent.getErrorDescription( pr.projectsErrorCode ) + '.';
		
		if ( pr.projectsErrorCode == APIError.MAX_PROJECTS_FOR_BASIC_MODE_EXCEEDED )
		{
			currentState = 'forBasicModeExceeded';
			str += '<br><br>Для неограниченного количества миксов подключай режим <b>PRO</b>!';
		}
		else
		{
			currentState = 'perDayExceeded';
		}
	}
	
	caption.textFlow = TextConverter.importToFlow( str, TextConverter.TEXT_FIELD_HTML_FORMAT );
}

private function onCloseClick() : void
{
	dispatchEvent( new CloseEvent( CloseEvent.CLOSE ) );
}

private function onProClick() : void
{
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.PRO_ADVANTAGES, null, initializedAction.fromIndex, initializedAction.fromState ) );
}