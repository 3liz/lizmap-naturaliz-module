<div class="dock-content">

  <ul class="nav nav-tabs">

    {if $presentation}
    <li class="active"><a data-toggle="tab" href="#occtax-presentation">Présentation</a></li>
    {/if}

    {if $legal}
    <li><a data-toggle="tab" href="#occtax-mentions">Mentions légales</a></li>
    {/if}

  </ul>

  <div class="tab-content">

    {if $presentation}
    <div id="occtax-presentation" class="tab-pane active">
      {$presentation}
    </div>
    {/if}

    {if $legal}
    <div id="occtax-mentions" class="tab-pane">
      {$legal}
    </div>
    {/if}

  </div>

</div>
