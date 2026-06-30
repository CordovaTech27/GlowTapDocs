interface ChartTooltipProps {
  active?: boolean
  payload?: Array<{ name?: string; value?: number; color?: string }>
  label?: string
}

export function ChartTooltip({ active, payload, label }: ChartTooltipProps) {
  if (!active || !payload?.length) return null

  return (
    <div className="rounded-xl border border-[#E2E8F0] bg-white px-4 py-3 shadow-[0_8px_32px_rgba(123,0,255,0.12)]">
      <p className="mb-2 text-xs font-semibold text-[#6B7A88]">{label}</p>
      <div className="space-y-1.5">
        {payload.map((entry) => (
          <div key={entry.name} className="flex items-center gap-2 text-sm">
            <span
              className="h-2.5 w-2.5 rounded-full"
              style={{ backgroundColor: entry.color }}
            />
            <span className="text-[#6B7A88]">{entry.name}:</span>
            <span className="font-semibold text-[#1E2A32]">
              ₹{Number(entry.value).toLocaleString('en-IN')}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
