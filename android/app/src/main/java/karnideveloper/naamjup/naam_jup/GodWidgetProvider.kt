package karnideveloper.naamjup.naam_jup

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class GodWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Get the widget data saved by Flutter using HomeWidget.saveWidgetData()
        val data = HomeWidgetPlugin.getData(context)
        val totalCount = data.getInt("total_count", 108) // default 0 if nothing yet saved

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_god_counter)

            // 🪔 Set title (e.g., राम राम)
            views.setTextViewText(R.id.widget_raam, "🔱 राम राम")

            // 🧮 Show the total count from Flutter
            views.setTextViewText(R.id.widget_count, totalCount.toString())

            // 👉 When user taps anywhere on the widget, open the main app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // ✅ Apply update
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
