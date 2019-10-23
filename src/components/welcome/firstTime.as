import classes.api.social.vk.VKApi;

import components.welcome.Slides;
import components.welcome.events.GoToEvent;

import mx.events.IndexChangedEvent;

import spark.utils.TextFlowUtil;

private function onShow() : void
{
	ApplicationModel.userInfo.visible = false;
}

private function creationComplete() : void
{
	title.textFlow = TextFlowUtil.importFromString( '<span fontWeight="bold">' + VKApi.userName + '</span>, Добро Пожаловать в Музыкальный Конструктор!' );
}

private function nextClick() : void
{
	dispatchEvent( new GoToEvent( GoToEvent.GO, Slides.VIDEO, 'firstTime' ) );
}

