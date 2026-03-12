package app.services;

import app.models.CmsModels;
import app.services.ICmsService;
import app.util.PageLoader;
import app.util.PageSerializer;
import app.util.VersionRestorer;
import app.util.JsonValidator;
import app.util.ComponentSchema;
import haxe.Json;
import sidewinder.interfaces.IDatabaseService;
import sidewinder.core.DI;

class CmsService implements ICmsService {
	private var db:IDatabaseService;
	private var loader:PageLoader;
	private var serializer:PageSerializer;
	private var restorer:VersionRestorer;
	private var validator:JsonValidator;

	public function new(?db:IDatabaseService, ?loader:PageLoader, ?serializer:PageSerializer, ?restorer:VersionRestorer) {
		this.db = db != null ? db : DI.get(IDatabaseService);
		this.loader = loader != null ? loader : DI.get(PageLoader);
		this.serializer = serializer != null ? serializer : DI.get(PageSerializer);
		this.restorer = restorer != null ? restorer : DI.get(VersionRestorer);
		this.validator = new JsonValidator();
	}

	public function createPage(request:CreatePageRequest, userId:String):CreatePageResponse {
		try {
			if (request.slug == null || request.slug.length == 0) {
				return {success: false, error: "Slug is required"};
			}
			if (request.title == null || request.title.length == 0) {
				return {success: false, error: "Title is required"};
			}

			// Validate slug format (only allow a-z, 0-9, dash, underscore, min 3 chars)
			var slugRegex = ~/^[a-z0-9_\/-]{3,}$/i;
			if (!slugRegex.match(request.slug)) {
				return {success: false, error: "Invalid slug format"};
			}
			// Check for duplicate slug
			var conn = db.acquire();
			try {
				var params = new Map<String, Dynamic>();
				params.set("slug", request.slug);
				var sql = "SELECT id FROM pages WHERE slug = @slug";
				var rs = conn.request(db.buildSql(sql, params));
				if (rs.hasNext()) {
					db.release(conn);
					return {success: false, error: "Duplicate slug"};
				}

				var layout = request.layout != null ? request.layout : "default";
				var pageId = serializer.createPage(request.slug, request.title, layout, request.components, request.seoHtml, conn);

				db.release(conn);
				return {success: true, pageId: pageId};
			} catch (e:Dynamic) {
				db.release(conn);
				return {success: false, error: "Error checking or creating slug: " + Std.string(e)};
			}
		} catch (e:Dynamic) {
			return {success: false, error: 'Error creating page: $e'};
		}
	}

	public function updatePage(id:Int, request:UpdatePageRequest, userId:String):UpdatePageResponse {
		try {
			// Validate the page DTO
			var pageDto:PageDTO = {
				pageId: id,
				title: request.title,
				layout: request.layout,
				slug: request.slug,
				components: request.components,
				visibilityConfig: request.visibilityConfig != null ? request.visibilityConfig : {
					visibilityMode: "Public",
					groupIds: []
				}
			};

			var validationResult = validator.validatePageDTO(pageDto);
			if (!validationResult.ok) {
				return {
					success: false,
					error: "Validation failed: " + validationResult.errors.map(e -> e.message).join(", ")
				};
			}

			// Do not update slug/title on draft save

			var versionId = serializer.savePageVersion(pageDto, userId, request.seoHtml);

			// Get the version number
			var version = loader.loadVersion(versionId);

			return {
				success: true,
				versionId: versionId,
				versionNum: version.versionNum,
				seoHtml: version.seoHtml
			};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error updating page: $e'};
		}
	}

	public function getPage(id:Int):GetPageResponse {
		try {
			var page = loader.loadLatest(id);
			return {success: true, page: page};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error loading page: $e'};
		}
	}

	public function getPageBySlug(slug:String, ?published:Bool = true):GetPageResponse {
		try {
			var page = loader.loadBySlug(slug, published);
			return {success: true, page: page};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error loading page: $e'};
		}
	}

	public function listPages():ListPagesResponse {
		try {
			var pages = loader.listPages();
			return {success: true, pages: pages};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error listing pages: $e'};
		}
	}

	public function publishVersion(pageId:Int, versionId:Int, userId:String):CreatePageResponse {
		try {
			// Publish the version
			// Get published version details
			var publishedVersion = loader.loadVersion(versionId);

			// Update page meta and visibilityConfig
			serializer.updatePageMeta(pageId, publishedVersion.title, publishedVersion.slug, publishedVersion.visibilityConfig);

			// Publish the version
			serializer.publishVersion(pageId, versionId);

			return {success: true};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error publishing version: $e'};
		}
	}

	public function restoreVersion(versionId:Int, userId:String):UpdatePageResponse {
		try {
			var newVersionId = restorer.restoreVersion(versionId, userId);
			var version = loader.loadVersion(newVersionId);
			return {
				success: true,
				versionId: newVersionId,
				versionNum: version.versionNum
			};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error restoring version: $e'};
		}
	}

	public function listVersions(pageId:Int):Dynamic {
		try {
			var versions = loader.listVersions(pageId);
			return {success: true, versions: versions};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error listing versions: $e'};
		}
	}

	public function uploadAsset(request:UploadAssetRequest, userId:String):UploadAssetResponse {
		try {
			if (request.pageId <= 0) {
				return {success: false, error: "Valid pageId is required"};
			}
			if (request.filename == null || request.filename.length == 0) {
				return {success: false, error: "Filename is required"};
			}
			if (request.data == null || request.data.length == 0) {
				return {success: false, error: "Asset data is required"};
			}

			var assetId = serializer.uploadAsset(request.pageId, request.filename, request.mime, request.data);
			return {success: true, assetId: assetId};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error uploading asset: $e'};
		}
	}

	public function getAsset(assetId:Int):Dynamic {
		try {
			var asset = loader.getAsset(assetId);
			return {success: true, asset: asset};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error getting asset: $e'};
		}
	}

	public function listAssets(pageId:Int):Dynamic {
		try {
			var assets = loader.listAssets(pageId);
			return {success: true, assets: assets};
		} catch (e:Dynamic) {
			return {success: false, error: 'Error listing assets: $e'};
		}
	}

	public function validateComponents(json:String):ValidationResult {
		return validator.validateJson(json);
	}

	public function generateAiPrompt(prompt:String):Dynamic {
		var componentTypes = ComponentSchema.getTypeList();
		var aiPrompt = validator.buildAiPrompt(prompt, componentTypes);
		return {
			success: true,
			prompt: aiPrompt,
			componentTypes: componentTypes
		};
	}

	public function getComponentTypes():Array<String> {
		return ComponentSchema.getTypeList();
	}
}
