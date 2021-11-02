<div style="height:100%;overflow:auto;">
    <h3 class="">
        <span class="title">
            <span class="icon search"></span>&nbsp;
            <span id="occtax-search-history-title" class="text">{@search.historique.dock.title@}</span>
            <span id="occtax-search-history-title-counter" class="text" style="font-size: 0.8em;"></span>
        </span>
    </h3>
    <div class="menu-content">
        <!-- <p id="occtax-search-history-description" style="max-width: 300px;"></p> -->
        <!-- Search history -->
        <div>
            <select id="occtax-search-history-select" size="10" multiple="multiple">
            </select>
        </div>

        <div class="btn-group">
            <button id="occtax-search-history-play" type="button" class="btn btn-mini" title="{@search.historique.button.play.title@}">
                <i class="icon-play"></i>
            </button>
            <button id="occtax-search-history-star" type="button" class="btn btn-mini" title="{@search.historique.button.star.title@}">
                <i class="icon-star"></i>
            </button>
            <button id="occtax-search-history-rename" type="button" class="btn btn-mini" title="{@search.historique.button.rename.title@}">
                <i class="icon-pencil"></i>
            </button>
            <button id="occtax-search-history-delete" type="button" class="btn btn-mini" title="{@search.historique.button.delete.title@}">
                <i class="icon-trash"></i>
            </button>
        </div>

        <!-- Invisible form to get and send history items -->
        <form style="display:none;" id="form_occtax_history_getter" method="post" action="{jurl 'occtax~history:getSearchHistory'}">
            <input type="text" name="content" value=''></input>
        </form>

    </div>
</div>
