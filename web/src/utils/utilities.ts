import { isValid, parse } from "date-fns";
import { Activity, Client } from "src/db/database";

export const toTitleCase = (str: string, exceptions: string[] = []) => {
    return str.split(' ').map(word => {
        return exceptions.includes(word.toUpperCase()) ? word.toUpperCase() : word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
    }).join(' ');
};

// Utility function for formatting Date
export const formatDate = (date: Date): string => {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');
    return `${year}/${month}/${day} at ${hours}:${minutes}:${seconds} EST`;
}

export const parseDateWithTwoDigitYear = (dateString: string) => {
    const dateFormats = ['yyyy-MM-dd', 'MM/dd/yyyy', 'MM/dd/yy', 'MM-dd-yy', 'MM-dd-yyyy'];
    let parsedDate = null;

    for (const format of dateFormats) {
        parsedDate = parse(dateString, format, new Date());
        if (isValid(parsedDate)) {
            // Handle two-digit year
            const year = parsedDate.getFullYear();
            if (year < 100) {
                parsedDate.setFullYear(year + 2000);
            }
            break;
        }
    }

    return parsedDate;
};

export const amortize = (activityState: Activity, clientState: Client) => {
        const activity = {
            parentDocId: clientState!.cid ?? '',
            time: activityState.time,
            recipient: activityState.recipient,
            fund: activityState.fund,
            sendNotif: activityState.sendNotif,
            isDividend: activityState.isDividend,
            notes: activityState.notes,
            isAmortization: true,
            amortizationCreated: true,
            parentName: clientState!.firstName + ' ' + clientState!.lastName
        }
        
        const profit: Activity = {
            ...activity,
            type: 'profit',
            amount: activityState.amount - (activityState.principalPaid ?? 0),
        }

        const withdrawal: Activity = {
            ...activity,
            type: 'withdrawal',
            amount: activityState.principalPaid ?? 0,
        }

        return [profit, withdrawal];
}

export function toSentenceCase(str: string) {
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}