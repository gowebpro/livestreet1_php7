{**
 * Базовый шаблон топика
 * Используется также для отображения превью топика
 *
 * @param object  $topic
 * @param boolean $isList
 * @param boolean $isPreview
 *}

{$component = 'ls-topic'}

{* Генерируем копии локальных переменных, *}
{* чтобы их можно было изменять в дочерних шаблонах *}
{foreach [ 'topic', 'isPreview', 'isList', 'mods', 'classes', 'attributes' ] as $param}
    {assign var="$param" value=$smarty.local.$param}
{/foreach}

{$user = $topic->getUser()}
{$type = ($topic->getType()) ? $topic->getType() : $smarty.local.type}

{if ! $isList}
    {$mods = "{$mods} single"}
{/if}

{$classes = "{$classes} topic js-topic"}

{block 'topic_options'}{/block}

<article class="{$component} {cmods name=$component mods=$mods} {$classes}" {cattr list=$attributes}>
    {**
     * Хидер
     *}
    {block 'topic_header'}
        <header class="{$component}-header">
            {* Заголовок *}
            <h1 class="{$component}-title word-wrap">
                {block 'topic_title'}
                    {if $topic->getPublish() == 0}
                        {component 'icon' icon='file' attributes=[ title => {lang 'topic.is_draft'} ]}
                    {/if}

                    {if $isList}
                        <a href="{$topic->getUrl()}">{$topic->getTitle()|escape}</a>
                    {else}
                        {$topic->getTitle()|escape}
                    {/if}
                {/block}
            </h1>

            {* Информация *}
            <ul class="{$component}-info">
                {block 'topic_header_info'}
                    {if ! $isPreview}
                        {foreach $topic->getBlogs() as $blog}
                            {if $blog->getType() != 'personal'}
                                <li class="{$component}-info-item {$component}-info-item--blog">
                                    <a href="{$blog->getUrlFull()}">{$blog->getTitle()|escape}</a>
                                </li>
                            {/if}
                        {/foreach}
                    {/if}

                    <li class="{$component}-info-item {$component}-info-item--date">
                        <time datetime="{date_format date=$topic->getDatePublish() format='c'}" title="{date_format date=$topic->getDatePublish() format='j F Y, H:i'}">
                            {date_format date=$topic->getDatePublish() format="j F Y, H:i"}
                        </time>
                    </li>
                {/block}
            </ul>

            {* Управление *}
            {if $topic->getIsAllowAction() && ! $isPreview}
                {block 'topic_header_actions'}
                    {$items = [
                        [ 'icon' => 'edit', 'url' => $topic->getUrlEdit(), 'text' => $aLang.common.edit, 'show' => $topic->getIsAllowEdit() ],
                        [ 'icon' => 'trash', 'url' => "{$topic->getUrlDelete()}?security_ls_key={$LIVESTREET_SECURITY_KEY}", 'text' => $aLang.common.remove, 'show' => $topic->getIsAllowDelete(), 'classes' => 'js-confirm-remove-default' ]
                    ]}
                {/block}

                {component 'actionbar' items=[[ 'buttons' => $items ]]}
            {/if}
        </header>
    {/block}


    {**
     * Текст
     *}
    {block 'topic_body'}
        {* Превью *}
        {$previewImage = $topic->getPreviewImageWebPath('900x300crop')}

        {if $previewImage}
            <div class="topic-preview-image">
                <img src="{$previewImage}" />
            </div>
        {/if}

        <div class="{$component}-content">
            <div class="{$component}-text ls-text">
                {block 'topic_content_text'}
                    {if $isList and $topic->getTextShort()}
                        {$topic->getTextShort()}
                    {else}
                        {$topic->getText()}
                    {/if}
                {/block}
            </div>

            {* Кат *}
            {if $isList && $topic->getTextShort()}
                {component 'button'
                    classes = "{$component}-cut"
                    url     = "{$topic->getUrl()}#cut"
                    text    = "{$topic->getCutText()|default:$aLang.topic.read_more}"}
            {/if}
        </div>

        {* Дополнительные поля *}
        {block 'topic_content_properties'}
            {if ! $isList}
                {component 'property' template='output.list' properties=$topic->property->getPropertyList()}
            {/if}
        {/block}

        {* Опросы *}
        {block 'topic_content_polls'}
            {if ! $isList}
                {component 'poll' template='list' polls=$topic->getPolls()}
            {/if}
        {/block}
    {/block}


    {**
     * Футер
     *}
    {block 'topic_footer'}
        {if ! $isList && $topic->getTypeObject()->getParam('allow_tags')}
            {$favourite = $topic->getFavourite()}

            {if ! $isPreview}
                {component 'tags-favourite'
                    tags          = $topic->getTagsArray()
                    tagsFavourite = ( $favourite ) ? $favourite->getTagsArray() : []
                    isEditable    = ! $favourite
                    targetType    = 'topic'
                    targetId      = $topic->getId()}
            {/if}
        {/if}

        <footer class="{$component}-footer">
            {* Информация *}
            {block 'topic_footer_info'}
                <ul class="{$component}-info clearfix">
                    {block 'topic_footer_info_items'}
                        {* Голосование *}
                        {if ! $isPreview}
                            <li class="{$component}-info-item {$component}-info-item--vote">
                                {$isExpired = strtotime($topic->getDatePublish()) < $smarty.now - Config::Get('acl.vote.topic.limit_time')}

                                {component 'vote'
                                         target     = $topic
                                         classes    = 'js-vote-topic'
                                         mods       = 'small white topic'
                                         useAbstain = true
                                         isLocked   = ( $oUserCurrent && $topic->getUserId() == $oUserCurrent->getId() ) || $isExpired
                                         showRating = $topic->getVote() || ($oUserCurrent && $topic->getUserId() == $oUserCurrent->getId()) || $isExpired}
                            </li>
                        {/if}

                        {* Автор топика *}
                        <li class="{$component}-info-item {$component}-info-item--author">
                            {component 'user' template='avatar' user=$user size='xsmall' mods='inline'}
                        </li>

                        {* Ссылка на комментарии *}
                        {* Не показываем если комментирование запрещено и кол-во комментариев равно нулю *}
                        {if $isList && ( ! $topic->getForbidComment() || ( $topic->getForbidComment() && $topic->getCountComment() ) )}
                            <li class="{$component}-info-item {$component}-info-item--comments">
                                <a href="{$topic->getUrl()}#comments">
                                    {lang name='comments.comments_declension' count=$topic->getCountComment() plural=true}
                                </a>

                                {if $topic->getCountCommentNew()}<span>+{$topic->getCountCommentNew()}</span>{/if}
                            </li>
                        {/if}

                        {if ! $isList && ! $isPreview}
                            {* Избранное *}
                            <li class="{$component}-info-item {$component}-info-item--favourite">
                                {component 'favourite' classes="js-favourite-{$type}" target=$topic}
                            </li>

                            {* Поделиться *}
                            <li class="{$component}-info-item {$component}-info-item--share">
                                {component 'icon' icon='share'
                                    classes="js-popover-default"
                                    attributes=[
                                        'title' => {lang 'topic.share'},
                                        'data-tooltip-target' => "#topic_share_{$topic->getId()}"
                                    ]}
                            </li>
                        {/if}
                    {/block} {* /topic_footer_info_items *}
                </ul>
            {/block} {* /topic_footer_info *}
        </footer>

        {* Всплывающий блок появляющийся при нажатии на кнопку Поделиться *}
        {if ! $isPreview}
            <div class="ls-tooltip" id="topic_share_{$topic->getId()}">
                <div class="ls-tooltip-content js-ls-tooltip-content">
                    {hookb run="topic_share" topic=$topic isList=$isList}
                        <div class="yashare-auto-init" data-yashareTitle="{$topic->getTitle()|escape}" data-yashareLink="{$topic->getUrl()}" data-yashareL10n="ru" data-yashareType="small" data-yashareTheme="counter" data-yashareQuickServices="yaru,vkontakte,facebook,twitter,odnoklassniki,moimir,gplus"></div>
                    {/hookb}
                </div>
            </div>
        {/if}
    {/block} {* /topic_footer *}
</article>