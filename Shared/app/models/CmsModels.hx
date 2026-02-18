package app.models;

import app.models.VisibilityConfig;
import Date;

typedef PageComponentDTO = {
	id:Int,
	type:String,
	sort:Int,
	data:Dynamic,
	visibilityConfig:VisibilityConfig
};

typedef PageVersionDTO = {
	id:Int,
	pageId:Int,
	versionNum:Int,
	title:String,
	layout:String,
	slug:String,
	createdAt:Date,
	createdBy:String,
	components:Array<PageComponentDTO>,
	seoHtml:String // cached SEO HTML
	,
	visibilityConfig:VisibilityConfig
};

typedef PageDTO = {
	pageId:Int,
	title:String,
	layout:String,
	slug:String,
	components:Array<PageComponentDTO>,
	visibilityConfig:VisibilityConfig
};

typedef CreatePageRequest = {
	slug:String,
	title:String,
	layout:String,
	?components:Array<PageComponentDTO>,
	?seoHtml:String
};

typedef CreatePageResponse = {
	success:Bool,
	?pageId:Null<Int>,
	?error:String
};

typedef UpdatePageRequest = {
	pageId:Int,
	title:String,
	layout:String,
	components:Array<PageComponentDTO>,
	slug:String,
	?seoHtml:String,
	visibilityConfig:VisibilityConfig
};

typedef UpdatePageResponse = {
	success:Bool,
	?versionId:Null<Int>,
	?versionNum:Null<Int>,
	?error:String,
	?seoHtml:String
};

typedef GetPageResponse = {
	success:Bool,
	?page:PageVersionDTO,
	?error:String
};

typedef ListPagesResponse = {
	success:Bool,
	?pages:Array<PageListItem>,
	?error:String
};

typedef PageListItem = {
	id:Int,
	slug:String,
	title:String,
	createdAt:Date
};

typedef PageAssetDTO = {
	id:Int,
	pageId:Int,
	filename:String,
	mime:String,
	createdAt:Date
};

typedef UploadAssetRequest = {
	pageId:Int,
	filename:String,
	mime:String,
	data:String // base64 encoded
};

typedef UploadAssetResponse = {
	success:Bool,
	?assetId:Null<Int>,
	?error:String
};

typedef ValidationError = {
	message:String,
	?details:String,
	?component:Dynamic
};

typedef ValidationResult = {
	ok:Bool,
	errors:Array<ValidationError>
};

typedef AiGenerateRequest = {
	pageId:Int,
	prompt:String,
	?assets:Array<Int> // asset IDs
};

typedef AiGenerateResponse = {
	success:Bool,
	?components:Array<PageComponentDTO>,
	?error:String
};
